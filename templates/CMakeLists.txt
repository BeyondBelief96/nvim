# Minimal starting point for a C++ project that works well with this config.
#
# The critical line is CMAKE_EXPORT_COMPILE_COMMANDS: it produces
# build/compile_commands.json, which is how clangd learns your include paths,
# defines and standard. Without it you get "file not found" on every #include.
cmake_minimum_required(VERSION 3.20)
project(myproject LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_executable(myproject
  src/main.cpp
)

target_include_directories(myproject PRIVATE include)
target_compile_options(myproject PRIVATE -Wall -Wextra -Wpedantic)
