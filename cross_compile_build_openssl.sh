#!/bin/bash

#. ./cross_compile_common.sh

function cross_compile_build_openssl() {
  target_os="linux-generic32"

  pushd openssl
  [ -d $cross_compile_build_dir ] && return
  ./Configure\
    $target_os\
    --prefix=$PWD/$cross_compile_build_dir\
    --openssldir=$PWD/$cross_compile_build_dir/openssl\
    --cross-compile-prefix=$cross_compile_bin_prefix

  cross_compile_common_build 0 0 1
  popd
}

#cross_compile_build_openssl
