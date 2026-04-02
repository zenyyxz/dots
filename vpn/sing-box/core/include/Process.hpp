#pragma once
#include <string>
#include <unistd.h>
#include <sys/wait.h>
#include <signal.h>
#include <iostream>
#include <vector>
#include <fstream>

namespace Vpn {
    class Process {
    private:
        pid_t child_pid = -1;
        std::string binary_path;
        std::string config_path;

    public:
        Process(const std::string& bin, const std::string& conf) 
            : binary_path(bin), config_path(conf) {}

        bool is_running() {
            if (child_pid <= 0) return false;
            int status;
            pid_t result = waitpid(child_pid, &status, WNOHANG);
            if (result == 0) return true; // Still running
            child_pid = -1;
            return false;
        }

        bool start() {
            if (is_running()) return true;

            child_pid = fork();
            if (child_pid == 0) { // Child
                char* const args[] = {
                    (char*)binary_path.c_str(),
                    (char*)"run",
                    (char*)"-c",
                    (char*)config_path.c_str(),
                    NULL
                };
                execv(binary_path.c_str(), args);
                exit(1); // Should not reach here
            } else if (child_pid < 0) {
                return false;
            }
            return true;
        }

        void stop() {
            if (child_pid > 0) {
                kill(child_pid, SIGTERM);
                int status;
                waitpid(child_pid, &status, 0);
                child_pid = -1;
            }
        }
    };
}
