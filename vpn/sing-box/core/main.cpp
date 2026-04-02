#include "include/Config.hpp"
#include "include/Process.hpp"
#include "include/Server.hpp"
#include <iostream>
#include <csignal>

using namespace Vpn;

int main(int argc, char** argv) {
    const std::string config_file = "/home/zenyyxz/dotfiles/vpn/sing-box/config.json";
    const std::string binary_path = "/home/zenyyxz/dotfiles/vpn/sing-box/sing-box";
    const std::string socket_path = "/tmp/vpn-core.sock";

    Config config;
    config.load_from_json(config_file); // Load current state first
    Process vpn_process(binary_path, config_file);
    Server server(socket_path);

    // Initial save - safe to do now with updated template
    config.save(config_file); 

    server.register_method("status", [&](const json& params) -> json {
        return {{"running", vpn_process.is_running()}};
    });

    server.register_method("start", [&](const json& params) -> json {
        return {{"success", vpn_process.start()}};
    });

    server.register_method("stop", [&](const json& params) -> json {
        vpn_process.stop();
        return {{"success", true}};
    });

    server.register_method("set_config", [&](const json& params) -> json {
        if (params.contains("server_ip")) config.server_ip = params["server_ip"];
        if (params.contains("uuid")) config.uuid = params["uuid"];
        if (params.contains("sni")) config.sni = params["sni"];
        if (params.contains("mtu")) config.mtu = params["mtu"];
        if (params.contains("tun_stack")) config.tun_stack = params["tun_stack"];
        
        config.save(config_file);
        
        if (vpn_process.is_running()) {
            vpn_process.stop();
            vpn_process.start();
        }
        return {{"success", true}};
    });

    if (!server.start()) {
        std::cerr << "Failed to start server on " << socket_path << std::endl;
        return 1;
    }

    std::cout << "VPN Core started. Listening on " << socket_path << std::endl;

    while (true) {
        server.run_once();
        usleep(10000); // 10ms
    }

    return 0;
}
