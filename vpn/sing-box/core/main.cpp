#include "include/Config.hpp"
#include "include/Process.hpp"
#include "include/Server.hpp"
#include <iostream>
#include <csignal>
#include <algorithm>
#include <fstream>
#include <unistd.h>

using namespace Vpn;

Process* global_vpn_process = nullptr;
std::string global_socket_path = "/tmp/vpn-core.sock";
std::string global_pid_path = "/tmp/vpn-core.pid";

void cleanup(int signal) {
    std::cout << "\nCleaning up and exiting..." << std::endl;
    if (global_vpn_process) global_vpn_process->stop();
    unlink(global_socket_path.c_str());
    unlink(global_pid_path.c_str());
    exit(signal);
}

int main(int argc, char** argv) {
    // 1. Zombie Prevention: Check if already running
    if (access(global_pid_path.c_str(), F_OK) == 0) {
        std::ifstream pid_file(global_pid_path);
        pid_t old_pid;
        if (pid_file >> old_pid) {
            if (kill(old_pid, 0) == 0) {
                std::cerr << "VPN Core is already running with PID " << old_pid << std::endl;
                return 1;
            }
        }
    }

    // 2. Write current PID
    std::ofstream pid_file(global_pid_path);
    pid_file << getpid();
    pid_file.close();

    // 3. Setup Signal Handling
    signal(SIGINT, cleanup);
    signal(SIGTERM, cleanup);

    const std::string config_file = "/home/zenyyxz/dotfiles/vpn/sing-box/config.json";
    const std::string profiles_file = "/home/zenyyxz/dotfiles/vpn/sing-box/profiles.json";
    const std::string binary_path = "/home/zenyyxz/dotfiles/vpn/sing-box/sing-box";

    Config config;
    config.load_from_json(config_file); 
    ProfileManager profile_manager(profiles_file);
    Process vpn_process(binary_path, config_file);
    global_vpn_process = &vpn_process;
    Server server(global_socket_path);

    // Initial save
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

    server.register_method("add_vless", [&](const json& params) -> json {
        return {{"success", profile_manager.add_vless(params["link"])}};
    });

    server.register_method("remove_profile", [&](const json& params) -> json {
        profile_manager.remove(params["name"]);
        return {{"success", true}};
    });

    server.register_method("list_profiles", [&](const json& params) -> json {
        json list = json::array();
        for (auto& p : profile_manager.get_profiles()) list.push_back(p.name);
        return list;
    });

    server.register_method("active_profile", [&](const json& params) -> json {
        for (auto& p : profile_manager.get_profiles()) if (p.active) return p.name;
        return "";
    });

    server.register_method("apply_profile", [&](const json& params) -> json {
        Profile* p = profile_manager.get(params["name"]);
        if (p) {
            config.server_ip = p->server;
            config.server_port = p->port;
            config.uuid = p->uuid;
            config.sni = p->sni;
            config.save(config_file);
            profile_manager.set_active(p->name);
            
            if (vpn_process.is_running()) {
                vpn_process.stop();
                vpn_process.start();
            }
            return {{"success", true}};
        }
        return {{"success", false}, {"error", "Profile not found"}};
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
        std::cerr << "Failed to start server on " << global_socket_path << std::endl;
        return 1;
    }

    std::cout << "VPN Core started. Listening on " << global_socket_path << std::endl;

    while (true) {
        server.run_once();
        usleep(10000); // 10ms
    }

    return 0;
}
