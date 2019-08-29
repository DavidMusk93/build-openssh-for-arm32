set -ex

cores=`nproc`
cross_compile_build_dir="armbuild"
cross_compile_abi='arm-linux-gnueabihf'
cross_compile_toolchain_dir="/opt/toolchain/gcc-linaro-5.4.1-2017.05-x86_64_arm-linux-gnueabihf"
cross_compile_bin_dir="$cross_compile_toolchain_dir/bin"
cross_compile_bin_prefix="$cross_compile_bin_dir/$cross_compile_abi-"
#verbose='-v'

function find_compressed_tar_file() {
  ls -A | grep -iE "$1.*\.tar\.[g|b|x]z"
}

function unpack_dir() {
  top_most=`tar -tf $1 | head -n 1`
  echo ${top_most%/}
}

function unpack() {
  case $1 in
    *.tar.gz)
      tar $verbose -zxf $1
      ;;
    *.tar.bz)
      tar $verbose -jxf $1
      ;;
    *.tar.xz)
      tar $verbose -Jxf $1
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

function trim() {
  echo -n "$1"
}

function replace() {
  declare -r r_pattern='[[:blank:]]*=[[:blank:]]*).*'
  local key=${1%%=*}
  local val=${1##*=}
  key=`trim "$key"`
  val=`trim "$val"`
  sed -i -r "s#^($key$r_pattern#\1$val#" $2
}

function download_source() {
  [ -f $1 ] || return
  local url_list=(`cat $1`)
  local filename=''
  for url in "${url_list[@]}"; do
    filename=`basename $url`
    case $url in
      *zlib*)
        filename=zlib_$filename;;
    esac
    [ -f $filename ] && continue
    curl -L $url -o $filename
  done
}

function clean() {
  rm -rf ./openss*
  rm -f ./OpenSSL*
  rm -rf zlib*
  rm -f ./arm_ssh.tar
}
