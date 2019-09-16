#!/bin/bash

. ./cross_compile_common.sh
. ./cross_compile_build_zlib.sh
. ./cross_compile_build_openssl.sh
. ./cross_compile_build_openssh.sh

on_start
download_source ./url.txt

cross_compile_build_zlib &>/dev/null &
cross_compile_build_openssl &>/dev/null &
wait

cross_compile_build_openssh
on_finish ./release.sh
