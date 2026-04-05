cmake_minimum_required(VERSION 3.10)
project(study-bridge)

set(CMAKE_CXX_STANDARD 17)

find_package(PkgConfig REQUIRED)
pkg_check_modules(SQLITE3 REQUIRED sqlite3)

add_executable(study-bridge main.cpp)
target_link_libraries(study-bridge ${SQLITE3_LIBRARIES})
target_include_directories(study-bridge PRIVATE ${SQLITE3_INCLUDE_DIRS} /usr/include)
