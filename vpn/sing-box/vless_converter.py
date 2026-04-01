import sys
import json
import urllib.parse

def parse_vless(url):
    try:
        # Basic parsing of the URL
        parsed = urllib.parse.urlparse(url)
        if parsed.scheme != "vless":
            return None
        
        # Extract user info (UUID) and server info
        uuid = parsed.username
        server = parsed.hostname
        port = parsed.port or 443
        
        # Extract query parameters
        params = urllib.parse.parse_qs(parsed.query)
        
        # Extract fragment (Tag/Name)
        tag = urllib.parse.unquote(parsed.fragment) if parsed.fragment else "proxy"
        
        # Construct sing-box outbound
        outbound = {
            "type": "vless",
            "tag": "proxy",
            "server": server,
            "server_port": port,
            "uuid": uuid,
            "packet_encoding": params.get("packetEncoding", ["xudp"])[0]
        }
        
        # TLS / Reality settings
        security = params.get("security", ["none"])[0]
        if security in ["tls", "reality"]:
            tls_settings = {
                "enabled": True,
                "server_name": params.get("sni", [server])[0],
                "utls": {
                    "enabled": True,
                    "fingerprint": params.get("fp", ["chrome"])[0]
                }
            }
            
            if security == "reality":
                tls_settings["reality"] = {
                    "enabled": True,
                    "public_key": params.get("pbk", [""])[0],
                    "short_id": params.get("sid", [""])[0]
                }
            
            # Allow Insecure
            if params.get("allowInsecure", ["false"])[0] == "true":
                tls_settings["insecure"] = True
                
            outbound["tls"] = tls_settings

        # Flow for Vision
        flow = params.get("flow", [None])[0]
        if flow:
            outbound["flow"] = flow

        # Transport (WS, GRPC, etc)
        transport_type = params.get("type", [None])[0]
        if transport_type == "ws":
            outbound["transport"] = {
                "type": "websocket",
                "path": params.get("path", ["/"])[0],
                "headers": {
                    "Host": params.get("host", [server])[0]
                }
            }
        elif transport_type == "grpc":
            outbound["transport"] = {
                "type": "grpc",
                "service_name": params.get("serviceName", [""])[0]
            }

        return outbound
    except Exception as e:
        return None

def generate_full_config(outbound):
    # This matches your existing working DNS/TUN setup
    return {
      "log": { "level": "info", "timestamp": True },
      "dns": {
        "servers": [
          { "tag": "dns-remote", "address": "https://1.1.1.1/dns-query", "detour": "proxy" },
          { "tag": "dns-local", "address": "8.8.8.8", "detour": "direct" }
        ],
        "rules": [ { "outbound": "any", "server": "dns-local" } ],
        "strategy": "prefer_ipv4"
      },
      "inbounds": [
        {
          "type": "tun",
          "tag": "tun-in",
          "interface_name": "tun0",
          "inet4_address": "172.19.0.1/30",
          "auto_route": True,
          "strict_route": True,
          "stack": "system",
          "sniff": True
        }
      ],
      "outbounds": [
        outbound,
        { "type": "direct", "tag": "direct" },
        { "type": "dns", "tag": "dns-out" }
      ],
      "route": {
        "rules": [
          { "protocol": "dns", "outbound": "dns-out" },
          { "ip_is_private": True, "outbound": "direct" }
        ],
        "auto_detect_interface": True
      }
    }

if __name__ == "__main__":
    input_data = sys.stdin.read().strip()
    if input_data.startswith("vless://"):
        outbound = parse_vless(input_data)
        if outbound:
            print(json.dumps(generate_full_config(outbound), indent=2))
        else:
            sys.exit(1)
    else:
        # If it's already JSON, just echo it back (let apply_config handle it)
        print(input_data)
