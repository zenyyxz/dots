#!/bin/bash

# Configuration
TOR_USER="tor"
TOR_UID=$(id -u $TOR_USER 2>/dev/null || echo 43)
TOR_TRANSPORT=9040
TOR_DNSPORT=5353

# Custom Chain for Tor
TOR_CHAIN="TOR_PROXY"

flush_rules() {
    # 1. Restore resolv.conf
    [ -f /etc/resolv.conf.bak ] && mv /etc/resolv.conf.bak /etc/resolv.conf
    
    # 2. Clean up NAT rules
    iptables -t nat -D OUTPUT -j $TOR_CHAIN 2>/dev/null
    iptables -t nat -F $TOR_CHAIN 2>/dev/null
    iptables -t nat -X $TOR_CHAIN 2>/dev/null
    
    # 3. Clean up filter rules
    iptables -D OUTPUT -p udp -j REJECT 2>/dev/null
    iptables -D OUTPUT -o lo -j ACCEPT 2>/dev/null
    iptables -D OUTPUT -p udp --dport $TOR_DNSPORT -j ACCEPT 2>/dev/null
    
    # 4. Re-enable IPv6
    sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null
    sysctl -w net.ipv6.conf.default.disable_ipv6=0 >/dev/null
}

apply_rules() {
    # 1. Backup and Force DNS to localhost (Critical for reliability)
    cp /etc/resolv.conf /etc/resolv.conf.bak
    echo "nameserver 127.0.0.1" > /etc/resolv.conf

    # 2. Disable IPv6 to prevent leaks
    sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null
    sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null

    # 3. Create the custom chain
    iptables -t nat -N $TOR_CHAIN
    
    # 4. HIJACK DNS FIRST
    iptables -t nat -A $TOR_CHAIN -p udp --dport 53 -j REDIRECT --to-ports $TOR_DNSPORT
    iptables -t nat -A $TOR_CHAIN -p tcp --dport 53 -j REDIRECT --to-ports $TOR_DNSPORT
    
    # 5. Exclude the tor user
    iptables -t nat -A $TOR_CHAIN -m owner --uid-owner $TOR_UID -j RETURN
    
    # 6. Exclude local networks
    iptables -t nat -A $TOR_CHAIN -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A $TOR_CHAIN -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A $TOR_CHAIN -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A $TOR_CHAIN -d 192.168.0.0/16 -j RETURN
    
    # 7. Redirect all remaining TCP traffic to Tor
    iptables -t nat -A $TOR_CHAIN -p tcp -j REDIRECT --to-ports $TOR_TRANSPORT
    
    # 8. Apply the chain to OUTPUT
    iptables -t nat -I OUTPUT -j $TOR_CHAIN
    
    # 9. FILTER Table:
    iptables -I OUTPUT -o lo -j ACCEPT
    iptables -A OUTPUT -p udp --dport $TOR_DNSPORT -j ACCEPT
    iptables -A OUTPUT -p udp -j REJECT # Kill all other UDP leaks
}

case "$1" in
    start)
        flush_rules
        apply_rules
        echo "Tor transparent proxy active. System-wide anonymity enabled."
        ;;
    stop)
        flush_rules
        echo "Tor proxy disabled. System-wide anonymity disabled."
        ;;
esac
