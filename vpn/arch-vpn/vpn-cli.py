#!/usr/bin/env python3
import socket
import json
import sys

SOCKET_PATH = "/tmp/vpn-core.sock"

def call_method(method, params=None):
    payload = {
        "jsonrpc": "2.0",
        "method": method,
        "params": params or {},
        "id": 1
    }
    
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.connect(SOCKET_PATH)
            s.sendall(json.dumps(payload).encode())
            response = s.recv(4096)
            return json.loads(response.decode())
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: vpn-cli.py <method> [params_json]")
        sys.exit(1)
        
    method = sys.argv[1]
    params = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {}
    
    print(json.dumps(call_method(method, params), indent=2))
