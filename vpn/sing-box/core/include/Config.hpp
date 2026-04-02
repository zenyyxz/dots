#pragma once
#include <nlohmann/json.hpp>
#include <string>
#include <vector>
#include <fstream>
#include <iostream>

using json = nlohmann::json;

namespace Vpn {
    struct Config {
        std::string server_ip = "161.118.248.52";
        int server_port = 443;
        std::string uuid = "c4bd98c1-b83c-4b32-a086-40f67a7ec3ff";
        std::string sni = "aka.ms";
        int mtu = 1500;
        std::string tun_stack = "system"; // system, gvisor, mixed
        bool strict_route = true;

        void load_from_json(const std::string& path) {
            std::ifstream f(path);
            if (!f.is_open()) return;
            try {
                json j = json::parse(f);
                if (j.contains("inbounds")) {
                    for (auto& in : j["inbounds"]) {
                        if (in["type"] == "tun") {
                            if (in.contains("mtu")) mtu = in["mtu"];
                            if (in.contains("stack")) tun_stack = in["stack"];
                            if (in.contains("strict_route")) strict_route = in["strict_route"];
                        }
                    }
                }
                if (j.contains("outbounds")) {
                    for (auto& out : j["outbounds"]) {
                        if (out["tag"] == "proxy") {
                            server_ip = out["server"];
                            server_port = out["server_port"];
                            uuid = out["uuid"];
                            if (out.contains("tls") && out["tls"].contains("server_name")) {
                                sni = out["tls"]["server_name"];
                            }
                        }
                    }
                }
            } catch (...) {}
        }

        json generate_singbox_json() const {
            json j;
            
            j["log"] = {
                {"level", "info"},
                {"output", "/home/zenyyxz/dotfiles/vpn/sing-box/box.log"},
                {"timestamp", true}
            };

            j["dns"] = {
                {"servers", {
                    {
                        {"tag", "dns-remote"},
                        {"type", "https"},
                        {"server", "1.1.1.1"},
                        {"server_port", 443},
                        {"detour", "proxy"}
                    },
                    {
                        {"tag", "dns-fakeip"},
                        {"type", "fakeip"},
                        {"inet4_range", "198.18.0.0/15"}
                    }
                }},
                {"rules", {
                    {
                        {"query_type", {"A", "AAAA"}},
                        {"server", "dns-fakeip"},
                        {"rewrite_ttl", 1}
                    }
                }},
                {"strategy", "prefer_ipv4"},
                {"independent_cache", true}
            };

            j["inbounds"] = {
                {
                    {"type", "tun"},
                    {"tag", "tun-in"},
                    {"interface_name", "tun0"},
                    {"address", {"172.19.0.1/30"}},
                    {"mtu", mtu},
                    {"auto_route", true},
                    {"strict_route", strict_route},
                    {"stack", tun_stack},
                    {"route_exclude_address", {server_ip + "/32"}}
                },
                {
                    {"type", "direct"},
                    {"tag", "dns-in"},
                    {"listen", "127.0.0.1"},
                    {"listen_port", 53}
                }
            };

            j["outbounds"] = {
                {
                    {"type", "vless"},
                    {"tag", "proxy"},
                    {"server", server_ip},
                    {"server_port", server_port},
                    {"uuid", uuid},
                    {"tls", {
                        {"enabled", true},
                        {"server_name", sni},
                        {"insecure", true}
                    }}
                },
                {
                    {"tag", "direct"},
                    {"type", "direct"}
                }
            };

            j["route"] = {
                {"rules", {
                    {
                        {"protocol", "dns"},
                        {"action", "hijack-dns"}
                    },
                    {
                        {"port", 53},
                        {"action", "hijack-dns"}
                    },
                    {
                        {"inbound", "tun-in"},
                        {"action", "sniff"},
                        {"protocol", {"http", "tls", "quic"}}
                    },
                    {
                        {"ip_cidr", {server_ip + "/32"}},
                        {"action", "route"},
                        {"outbound", "direct"}
                    }
                }},
                {"auto_detect_interface", true},
                {"final", "proxy"}
            };

            return j;
        }

        void save(const std::string& path) const {
            std::ofstream f(path);
            f << generate_singbox_json().dump(2);
        }
    };
}
