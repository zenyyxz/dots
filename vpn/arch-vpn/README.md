# 🛡️ Arch VPN: The Zero-Data Shield

Welcome to your custom-built, high-performance VPN core! This project was born from a need to bypass restrictive ISP data blocks while keeping everything lightweight, fast, and integrated directly into your Hyprland desktop.

## ✨ Features
- **Unified Core**: A single C++ binary that handles everything.
- **Embedded Engine**: `sing-box` is baked right into the executable and runs entirely from memory (no disk wear!).
- **Zero-Data Magic**: Advanced DNS bootstrapping and SNI spoofing to get you online even with zero mobile data.
- **Instant Control**: Fully integrated into your Quickshell side panel for one-click toggling.
- **Native Profiles**: Simple VLESS link parsing and persistent profile management.

## 🏗️ How it works
The `vpn-core` manages the lifecycle of an embedded `sing-box` instance. When you hit **Start**, it:
1.  Creates a virtual file in RAM.
2.  Writes the embedded engine to it.
3.  Executes it with your custom "Zero-Data" configuration.
4.  Exposes a secure JSON-RPC API over a Unix socket (`/tmp/vpn-core.sock`) so the UI can stay in sync.

## 🚀 Usage

### Desktop (Recommended)
Just use the **VPN Manager** in your side panel! Paste a VLESS link, hit add, and click the shield to connect.

### CLI (For the hackers)
We have a handy Python script to talk to the core:
- **Check status**: `./vpn-cli.py status`
- **Connect**: `./vpn-cli.py start`
- **Disconnect**: `./vpn-cli.py stop`
- **Add a link**: `./vpn-cli.py add_vless "vless://..."`

## 📁 Project Map
- `vpn-core`: The main brain (C++ binary).
- `vpn-cli.py`: The messenger between you and the brain.
- `config.json`: The "Zero-Data" template (Core-managed).
- `profiles.json`: Your list of saved servers.
- `src/`: Where the C++ source code lives if you want to tinker.

---
*Built with ❤️ for your Hyprland setup.*
