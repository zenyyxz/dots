import sys
import json
import urllib.parse
import os
import socket

LOG_PATH = "/home/zenyyxz/dotfiles/vpn/sing-box/box.log"
BINARY_PATH = "/home/zenyyxz/dotfiles/vpn/sing-box/sing-box"

def get_ip(domain):
    try:
        return socket.gethostbyname(domain)
    except:
        return None

def parse_vless(url):
    try:
        parsed = urllib.parse.urlparse(url)
        if parsed.scheme != "vless": return None
        uuid = parsed.username
        server = parsed.hostname
        port = parsed.port or 443
        params = {k: v[0] for k, v in urllib.parse.parse_qs(parsed.query).items()}
        
        outbound = {
            "type": "vless",
            "tag": "proxy",
            "server": server,
            "server_port": port,
            "uuid": uuid
        }
        
        flow = params.get("flow")
        if flow: outbound["flow"] = flow

        security = params.get("security", "none")
        if security in ["tls", "reality"]:
            tls_settings = {
                "enabled": True,
                "server_name": params.get("sni", server),
                "insecure": True,
                "utls": { "enabled": True, "fingerprint": params.get("fp", "chrome") }
            }
            if security == "reality":
                tls_settings["reality"] = {
                    "enabled": True,
                    "public_key": params.get("pbk", ""),
                    "short_id": params.get("sid", "")
                }
            outbound["tls"] = tls_settings

        transport_type = params.get("type")
        if transport_type == "ws":
            outbound["transport"] = {
                "type": "websocket",
                "path": params.get("path", "/"),
                "headers": { "Host": params.get("host", server) }
            }
        elif transport_type == "grpc":
            outbound["transport"] = {
                "type": "grpc",
                "service_name": params.get("serviceName", "")
            }
            
        return outbound
    except Exception: return None

def generate_full_config(outbound):
    proxy_server = outbound.get("server", "")
    proxy_ip = get_ip(proxy_server)
    
    return {
      "log": {
        "level": "info",
        "output": LOG_PATH,
        "timestamp": True
      },
      "dns": {
        "servers": [
          { "tag": "dns-remote", "type": "udp", "server": "1.1.1.1", "detour": "proxy" },
          { "tag": "dns-local", "type": "local" }
        ],
        "rules": [
          { "outbound": "any", "server": "dns-local" },
          { "clash_mode": "Global", "server": "dns-remote" },
          { "clash_mode": "Direct", "server": "dns-local" }
        ],
        "final": "dns-local",
        "strategy": "prefer_ipv4"
      },
      "inbounds": [
        {
          "type": "tun",
          "tag": "tun-in",
          "interface_name": "tun0",
          "address": ["172.19.0.1/30"],
          "auto_route": True,
          "strict_route": True,
          "stack": "system",
          "mtu": 1500
        }
      ],
      "outbounds": [
        {
            **outbound,
            "domain_resolver": "dns-local"
        },
        { "type": "direct", "tag": "direct" },
        { "type": "block", "tag": "block" }
      ],
      "route": {
        "rules": [
          { "process_name": ["sing-box"], "outbound": "direct" },
          { "process_path": [BINARY_PATH], "outbound": "direct" },
          { "ip_is_private": True, "outbound": "direct" },
          { "protocol": "dns", "action": "hijack-dns" },
          { "port": 53, "action": "hijack-dns" },
          { "ip_version": 6, "action": "reject" },
          { "inbound": ["tun-in"], "action": "sniff" },
          { "domain": [proxy_server], "outbound": "direct" } if proxy_server else None,
          { "ip_cidr": [proxy_ip + "/32"], "outbound": "direct" } if proxy_ip else None,
          { "clash_mode": "Global", "outbound": "proxy" },
          { "clash_mode": "Direct", "outbound": "direct" }
        ],
        "auto_detect_interface": True,
        "final": "proxy"
      }
    }

if __name__ == "__main__":
    try:
        input_data = sys.stdin.read().strip()
        if not input_data: sys.exit(0)
        if input_data.startswith("vless://"):
            outbound = parse_vless(input_data)
            if outbound: 
                config = generate_full_config(outbound)
                config["route"]["rules"] = [r for r in config["route"]["rules"] if r is not None]
                print(json.dumps(config, indent=2))
            else: sys.exit(1)
        else:
            data = json.loads(input_data)
            if "dns" in data:
                data["dns"]["strategy"] = "prefer_ipv4"
                if "servers" in data["dns"]:
                    data["dns"]["servers"] = [s for s in data["dns"]["servers"] if s.get("tag") != "dns-local"]
                    data["dns"]["servers"].append({ "tag": "dns-local", "type": "local" })
                    for s in data["dns"]["servers"]:
                        if s.get("tag") != "dns-local": s["domain_resolver"] = "dns-local"
                        s.pop("detour", None) if s.get("tag") == "dns-local" else None
                data["dns"]["final"] = "dns-local"

            if "outbounds" in data:
                proxy_server = ""
                for o in data["outbounds"]:
                    if o.get("tag") == "proxy" or o.get("type") == "vless":
                        o["domain_resolver"] = "dns-local"
                        proxy_server = o.get("server", "")
                
                if "route" in data and "rules" in data["route"]:
                    data["route"]["rules"] = [r for r in data["route"]["rules"] if not r.get("process_name") and not r.get("process_path")]
                    data["route"]["rules"].insert(0, { "process_name": ["sing-box"], "outbound": "direct" })
                    data["route"]["rules"].insert(0, { "process_path": [BINARY_PATH], "outbound": "direct" })
                    
                    if proxy_server:
                        pip = get_ip(proxy_server)
                        if pip:
                            data["route"]["rules"].insert(0, { "ip_cidr": [pip + "/32"], "outbound": "direct" })
                        data["route"]["rules"].insert(0, { "domain": [proxy_server], "outbound": "direct" })

            if "route" in data:
                data["route"]["final"] = "proxy"
                data["route"]["auto_detect_interface"] = True
                if "rules" in data["route"]:
                    has_v6_reject = any(r.get("ip_version") == 6 and r.get("action") == "reject" for r in data["route"]["rules"])
                    if not has_v6_reject:
                        data["route"]["rules"].insert(0, { "ip_version": 6, "action": "reject" })
                    has_sniff = any(r.get("action") == "sniff" for r in data["route"]["rules"])
                    if not has_sniff:
                         data["route"]["rules"].insert(1, { "inbound": ["tun-in"], "action": "sniff" })

            if "inbounds" in data:
                for i in data["inbounds"]:
                    if i.get("type") == "tun":
                        i.pop("sniff", None) # Remove legacy field
                        i["stack"] = "system"
                        i["mtu"] = 1500

            print(json.dumps(data, indent=2))
    except Exception: print(input_data)
