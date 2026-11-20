#!/bin/bash
sudo pacman -S python-ply wayland-protocols lib32-llvm lib32-libxrandr lib32-libxdamage rust rust-bindgen cbindgen lib32-rust-libs lib32-libunwind meson ninja python-mako spirv-llvm-translator lib32-libva lib32-spirv-llvm-translator python-yaml

#potential fix for repo clone error
# git config --global http.version HTTP/1.1
# git config --global http.postBuffer 524288000
