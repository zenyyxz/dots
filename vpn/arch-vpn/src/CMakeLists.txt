cmake_minimum_required(VERSION 3.10)
project(vpn-core)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(include)
include_directories(/usr/include)

# --- Embedding sing-box ---
# This command converts the sing-box binary into an object file (.o) 
# that we can link directly into vpn-core.
# It creates symbols like _binary_sing_box_start and _binary_sing_box_end.
execute_process(
    COMMAND ld -r -b binary -o singbox_bin.o /home/zenyyxz/dotfiles/vpn/sing-box/sing-box
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)

add_executable(vpn-core main.cpp singbox_bin.o)

# Link against pthread for system calls
target_link_libraries(vpn-core pthread)
