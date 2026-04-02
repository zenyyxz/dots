#!/bin/bash

# Configuration
TOR_USER="tor"
TOR_UID=$(id -u $TOR_USER 2>/dev/null || echo 43)
TOR_TRANSPORT=9040
TOR_DNSPORT=5353

# Custom Chain for Tor
TOR_CHAIN="TOR_PROXY"

flush_rules() {
    iptables -t nat -D OUTPUT -j $TOR_CHAIN 2>/dev/null
    iptables -t nat -F $TOR_CHAIN 2>/dev/null
    iptables -t nat -X $TOR_CHAIN 2>/dev/null
    iptables -D OUTPUT -p udp -j REJECT 2>/dev/null
}

apply_rules() {
    iptables -t nat -N $TOR_CHAIN
    
    # 1. Redirect DNS to Tor
    iptables -t nat -A $TOR_CHAIN -p udp --dport 53 -j REDIRECT --to-ports $TOR_DNSPORT
    iptables -t nat -A $TOR_CHAIN -p tcp --dport 53 -j REDIRECT --to-ports $TOR_DNSPORT
    
    # 2. Exclude the tor user (to prevent loops)
    iptables -t nat -A $TOR_CHAIN -m owner --uid-owner $TOR_UID -j RETURN
    
    # 3. Exclude local networks
    iptables -t nat -A $TOR_CHAIN -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A $TOR_CHAIN -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A $TOR_CHAIN -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A $TOR_CHAIN -d 192.168.0.0/16 -j RETURN
    
    # 4. Redirect all remaining TCP traffic to Tor
    iptables -t nat -A $TOR_CHAIN -p tcp -j REDIRECT --to-ports $TOR_TRANSPORT
    
    # 5. Apply the chain to OUTPUT
    iptables -t nat -I OUTPUT -j $TOR_CHAIN
    
    # 6. Block all other UDP traffic (leaks)
    iptables -I OUTPUT -p udp -j REJECT
}

case "$1" in
    start)
        flush_rules
        apply_rules
        echo "Tor transparent proxy active."
        ;;
    stop)
        flush_rules
        echo "Tor proxy disabled."
        ;;
esac
