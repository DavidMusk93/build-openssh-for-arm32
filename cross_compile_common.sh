set -ex

cores=`nproc`
cross_compile_build_dir="armbuild"
cross_compile_abi='arm-linux-gnueabihf'
cross_compile_toolchain_dir="/opt/toolchain/gcc-linaro-5.4.1-2017.05-x86_64_arm-linux-gnueabihf"
cross_compile_bin_dir="$cross_compile_toolchain_dir/bin"
cross_compile_bin_prefix="$cross_compile_bin_dir/$cross_compile_abi-"

function find_compressed_tar_file() {
  ls -A | grep -E "$1.*\.tar\.[g|b|x]z"
}

function unpack_dir() {
  top_most=`tar -tf $1 | head -n 1`
  echo ${top_most%/}
}

function unpack() {
  case $1 in
    *.tar.gz)
      tar -zxvf $1
      ;;
    *.tar.bz)
      tar -jxvf $1
      ;;
    *.tar.xz)
      tar -Jxvf $1
      ;;
  esac
}

function init_lib() {
  local packed=`find_compressed_tar_file $1`
  local unpack_dir=`unpack_dir $packed`
  unpack $packed
  ln -sfn $unpack_dir $1
}

function cross_compile_common_build() {
  local do_push=$1
  local do_cmkae=$2
  local do_install=$3
  mkdir -p $cross_compile_build_dir
  [ $do_push -eq 1 ] && pushd $cross_compile_build_dir
  [ $do_cmkae -eq 1 ] && cmake ..
  make -j$cores
  [ $do_install -eq 1 ] && make install
  [ $do_push -eq 1 ] && popd
  return 0
}
