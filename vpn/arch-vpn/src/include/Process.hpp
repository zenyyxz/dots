#pragma once
#include <string>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>
#include <iostream>
#include <vector>

// These symbols are created by the linker (ld) when we embed the binary
extern "C" {
    extern char _binary__home_zenyyxz_dotfiles_vpn_sing_box_sing_box_start;
    extern char _binary__home_zenyyxz_dotfiles_vpn_sing_box_sing_box_end;
}

namespace Vpn {
    class Process {
    private:
        pid_t child_pid = -1;
        std::string config_path;

        /**
         * @brief Creates a file in RAM (memfd) and writes the embedded sing-box binary to it.
         * @return File descriptor to the memory file
         */
        int create_memfd_binary() {
            int fd = memfd_create("sing-box-embedded", MFD_CLOEXEC);
            if (fd == -1) return -1;

            size_t size = &_binary__home_zenyyxz_dotfiles_vpn_sing_box_sing_box_end - 
                         &_binary__home_zenyyxz_dotfiles_vpn_sing_box_sing_box_start;
            
            if (write(fd, &_binary__home_zenyyxz_dotfiles_vpn_sing_box_sing_box_start, size) != (ssize_t)size) {
                close(fd);
                return -1;
            }
            return fd;
        }

    public:
        Process(const std::string& conf) : config_path(conf) {}

        bool is_running() {
            if (child_pid <= 0) return false;
            int status;
            pid_t result = waitpid(child_pid, &status, WNOHANG);
            if (result == 0) return true;
            child_pid = -1;
            return false;
        }

        bool start() {
            if (is_running()) return true;

            int mem_fd = create_memfd_binary();
            if (mem_fd == -1) {
                std::cerr << "Failed to create memory-backed binary" << std::endl;
                return false;
            }

            child_pid = fork();
            if (child_pid == 0) { // Child
                char* const args[] = {
                    (char*)"sing-box",
                    (char*)"run",
                    (char*)"-c",
                    (char*)config_path.c_str(),
                    NULL
                };
                
                // Execute directly from the memory file descriptor
                fexecve(mem_fd, args, environ);
                
                // If fexecve fails
                perror("fexecve failed");
                exit(1);
            } else if (child_pid < 0) {
                close(mem_fd);
                return false;
            }
            
            // Parent doesn't need the FD anymore
            close(mem_fd);
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
