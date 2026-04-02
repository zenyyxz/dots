# Sing-box VLESS "Zero Data" VPN Client

This directory contains a high-performance transparent proxy client built with `sing-box`. It is specifically optimized for **Zero Data environments** using SNI spoofing and VLESS.

## The "Zero Data" Strategy
To connect without a data balance, we implemented three key pillars:
1.  **Direct IP Bootstrapping:** We use the server's raw IP (`161.118.248.52`) instead of a domain. This allows the proxy to start without needing a working DNS connection.
2.  **SNI Spoofing:** We use `aka.ms` (or Zoom/CDN domains) in the `server_name` field. This tricks the ISP firewall into thinking the traffic is part of a free/educational data package.
3.  **Fake-IP DNS:** Instead of waiting for a slow or blocked remote DNS, `sing-box` gives apps an instant "Fake IP" (`198.18.x.x`). The real resolution happens later, safely inside the tunnel.

---

## Configuration Breakdown (`config.json`)

### 1. DNS Section
*   **`dns-remote` (Type: `https`)**: Uses Google DNS (`1.1.1.1`) over HTTPS (DoH). This ensures your ISP cannot see or hijack your DNS queries. It is routed through the `detour: proxy` (the VLESS tunnel).
*   **`dns-fakeip` (Type: `fakeip`)**: Enables the Fake-IP engine. It maps domains to the `198.18.0.0/15` range.
*   **`rules`**: Specifically tells `sing-box` to use the `fakeip` server for all `A` and `AAAA` (IPv4/IPv6) record queries.

### 2. Inbounds Section
*   **`tun-in` (Type: `tun`)**: Creates a virtual network card (`tun0`).
    *   **`auto_route: true`**: Automatically sets up system routing tables.
    *   **`strict_route: true`**: Forces all system traffic into the tunnel and prevents leaks.
    *   **`route_exclude_address`**: Excludes the server IP to prevent a routing loop.
*   **`dns-in` (Type: `direct`)**: Listens on `127.0.0.1:53`. This allows the system to send standard DNS queries directly into `sing-box`.

### 3. Outbounds Section
*   **`proxy` (Type: `vless`)**: The main encrypted tunnel.
    *   **`uuid`**: Your private authentication key.
    *   **`tls.enabled`**: Encrypts the connection to look like standard web traffic.
    *   **`tls.server_name`**: The "Spoofed" domain used to bypass the ISP.
*   **`direct`**: A bypass used for the server's own IP address.

### 4. Route Section (Modern 1.13+ Syntax)
*   **`hijack-dns`**: Intercepts any outgoing DNS packets and redirects them to the internal DNS engine.
*   **`sniff` (Action)**: **CRITICAL.** This looks inside the traffic going to "Fake IPs" to see the actual domain name (HTTP/TLS SNI). This is how `sing-box` knows where to actually send your browser's request.
*   **`ip_cidr` rule**: Ensures traffic destined for the server IP itself is sent `direct` rather than through the tunnel.

---

## The "1.13 Migration" Fixes
During development, we encountered several `FATAL` crashes because the binary was newer than the configuration format.
1.  **Nested Sniffing:** Moved `sniff` from the `inbound` block to a standalone `action` in `route.rules`.
2.  **Typed DNS Servers:** Switched from simple address strings to the new `type: "https"` and `type: "fakeip"` object formats.
3.  **Atomic Status:** Updated the toggle script to use `printf` and pipe-separation to ensure the UI and system state stay perfectly synchronized.
