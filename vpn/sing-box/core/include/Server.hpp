#pragma once
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string>
#include <nlohmann/json.hpp>
#include <iostream>
#include <functional>
#include <map>

using json = nlohmann::json;

namespace Vpn {
    class Server {
    private:
        std::string socket_path;
        int server_fd = -1;
        std::map<std::string, std::function<json(const json&)>> methods;

    public:
        Server(const std::string& path) : socket_path(path) {}

        ~Server() {
            if (server_fd != -1) close(server_fd);
            unlink(socket_path.c_str());
        }

        void register_method(const std::string& name, std::function<json(const json&)> method) {
            methods[name] = method;
        }

        bool start() {
            server_fd = socket(AF_UNIX, SOCK_STREAM, 0);
            if (server_fd == -1) return false;

            struct sockaddr_un addr;
            memset(&addr, 0, sizeof(addr));
            addr.sun_family = AF_UNIX;
            strncpy(addr.sun_path, socket_path.c_str(), sizeof(addr.sun_path) - 1);

            unlink(socket_path.c_str());
            if (bind(server_fd, (struct sockaddr*)&addr, sizeof(addr)) == -1) return false;
            chmod(socket_path.c_str(), 0666); // Allow non-root users to talk to the core
            if (listen(server_fd, 5) == -1) return false;

            return true;
        }

        void run_once() {
            struct sockaddr_un client_addr;
            socklen_t client_len = sizeof(client_addr);
            int client_fd = accept(server_fd, (struct sockaddr*)&client_addr, &client_len);
            if (client_fd == -1) return;

            char buffer[4096];
            ssize_t n = read(client_fd, buffer, sizeof(buffer) - 1);
            if (n > 0) {
                buffer[n] = '\0';
                try {
                    json req = json::parse(buffer);
                    std::string method_name = req["method"];
                    json params = req.contains("params") ? req["params"] : json::object();
                    
                    json res;
                    if (methods.count(method_name)) {
                        res = {{"jsonrpc", "2.0"}, {"result", methods[method_name](params)}, {"id", req["id"]}};
                    } else {
                        res = {{"jsonrpc", "2.0"}, {"error", {{"code", -32601}, {"message", "Method not found"}}}, {"id", req["id"]}};
                    }
                    std::string res_str = res.dump();
                    write(client_fd, res_str.c_str(), res_str.size());
                } catch (...) {
                    // Ignore malformed JSON
                }
            }
            close(client_fd);
        }
    };
}
