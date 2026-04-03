# Sing-box "Zero Data" VPN Core (C++)

This directory contains a high-performance transparent proxy client built with a custom C++ core wrapper around `sing-box`. It is specifically optimized for **Zero Data environments** using SNI spoofing and VLESS.

## Features
- **Unified C++ Core**: Manages `sing-box` lifecycle, configuration generation, and profile storage.
- **Zero Data Bootstrap**: Uses a specialized DNS sequence (`dns-bootstrap`) to resolve server domains via ISP "free" lanes before the tunnel starts.
- **JSON-RPC API**: Exposes a Unix Socket API (`/tmp/vpn-core.sock`) for control.
- **Native VLESS Parser**: Automatically converts `vless://` links into optimized configurations.
- **Zombie Prevention**: Built-in PID locking and signal cleanup.

## The "Zero Data" Logic
To bypass ISP data blocks, the core generates a config with:
1.  **SNI Spoofing**: Forces `aka.ms` (or other free SNIs) at the TLS layer.
2.  **Bootstrap DNS**: Directs DNS queries for the VPN server to the system's local DNS *outside* the tunnel.
3.  **Loop Prevention**: Explicitly routes VPN server traffic through the `direct` outbound to prevent the tunnel from trying to encapsulate its own traffic.

## Architecture
- **`core/`**: C++ Source code and build files.
- **`core/vpn-cli.py`**: A lightweight Python helper to talk to the C++ core.
- **`config.json`**: Managed by the core (do not edit manually unless you know what you are doing).
- **`profiles.json`**: Stores your VLESS profiles.

## Usage (Manual)
1.  **Build**: `cd core/build && cmake .. && make`
2.  **Start Core**: `sudo ./core/build/vpn-core`
3.  **Toggle VPN**: `python3 core/vpn-cli.py start` / `stop`
4.  **Add Profile**: `python3 core/vpn-cli.py add_vless '<link>'`

## Integration
The system is integrated into the **Quickshell** side panel for easy one-click toggling and profile management.
