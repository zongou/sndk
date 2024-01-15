#!/bin/sh
set -eu

export ZIG=/data/data/com.termux/files/home/zig-linux-aarch64-0.12.0-dev.3609+ac21ade66/zig

export CLANG="${ZIG} clang"
export CLANGXX="${ZIG} clang -lc++"

# export CLANG=/data/data/com.termux/files/home/static-clang/bin/clang
# export CLANGXX=/data/data/com.termux/files/home/static-clang/bin/clang++

./bin/aarch64-linux-android24-clang tests/hello.c -o hello_c
./bin/aarch64-linux-android24-clang++ tests/hello.cpp -o hello_cpp
/system/bin/file hello_c
/system/bin/file hello_cpp
