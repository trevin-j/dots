cmake_minimum_required(VERSION 3.27)

project(hyprnospecialfade
    DESCRIPTION "Disable special workspace fade"
    VERSION 1.0
)

set(CMAKE_CXX_STANDARD 23)

add_library(hyprnospecialfade SHARED main.cpp)

find_package(PkgConfig REQUIRED)
pkg_check_modules(deps REQUIRED IMPORTED_TARGET
    hyprland
    libdrm
    libinput
    libudev
    pangocairo
    pixman-1
    wayland-server
    xkbcommon
)

target_link_libraries(hyprnospecialfade PRIVATE rt PkgConfig::deps)
