cmake_minimum_required(VERSION 3.10)
project(vpn-core)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(include)
include_directories(/usr/include)

add_executable(vpn-core main.cpp)

# Link against pthread for usleep and other sys calls if needed
target_link_libraries(vpn-core pthread)
