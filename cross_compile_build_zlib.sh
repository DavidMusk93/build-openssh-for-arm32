#!/bin/bash

#. ./cross_compile_common.sh

function clean_up() {
  rm -f /tmp/cross_compile_cmake.env
}

#trap 'clean_up' EXIT

cat > /tmp/cross_compile_cmake.env << eof
set(CMAKE_INSTALL_PREFIX "\${CMAKE_CURRENT_SOURCE_DIR}/$cross_compile_build_dir")
set(CMAKE_FIND_ROOT_PATH "$cross_compile_toolchain_dir/$cross_compile_abi")
set(CMAKE_C_COMPILER     "${cross_compile_bin_prefix}gcc")
set(CMAKE_CXX_COMPILER   "${cross_compile_bin_prefix}g++")
set(CMAKE_C_FLAGS        "-O2 -fomit-frame-pointer -ftree-vectorize -mfpu=neon-vfpv4 -mfloat-abi=hard")
set(CMAKE_CXX_FLAGS      "-O2 -fomit-frame-pointer -ftree-vectorize -mfpu=neon-vfpv4 -mfloat-abi=hard -std=c++11")
eof

function cross_compile_build_zlib() {
  [ -d $cross_compile_build_dir ] && return
  pushd zlib
  sed -i -e '/^set(VERSION/r /tmp/cross_compile_cmake.env' CMakeLists.txt
  cross_compile_common_build 1 1 1
  popd
}

#cross_compile_build_zlib
