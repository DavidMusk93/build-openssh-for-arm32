#!/bin/bash

. ./cross_compile_build_zlib.sh
. ./cross_compile_build_openssl.sh
. ./cross_compile_build_openssh.sh

cross_compile_build_zlib
cross_compile_build_openssl
cross_compile_build_openssh
