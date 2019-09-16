set -ex

cores=`nproc`
cross_compile_build_dir="armbuild"
cross_compile_abi='arm-linux-gnueabihf'
cross_compile_toolchain_dir="/opt/toolchain/gcc-linaro-5.4.1-2017.05-x86_64_arm-linux-gnueabihf"
cross_compile_bin_dir="$cross_compile_toolchain_dir/bin"
cross_compile_bin_prefix="$cross_compile_bin_dir/$cross_compile_abi-"
root_dir=$PWD
#verbose='-v'

function openssh_related_variable() {
  declare -g dw_dir="dw"
  declare -g openssh_deps=('zlib' 'openssl' 'openssh')
}

function on_start() {
  openssh_related_variable
  mkdir -p $dw_dir
}

function on_finish() {
  try_source $1 || return
  functor_exist do_release && do_release
}

function find_tar() {
  ls -A | grep -iE "$1.*\.tar\.[g|b|x]z"
}

function unpack_dirname() {
  local top_most=`tar -tf $1 | head -n 1`
  echo ${top_most%/}
}

function unpack() {
  case $1 in
    *.tar.gz)
      tar $verbose -zxf $1;;
    *.tar.bz)
      tar $verbose -jxf $1;;
    *.tar.xz)
      tar $verbose -Jxf $1;;
  esac
}

function init_lib() {
  pushd $dw_dir
  local packed=`find_tar $1`
  local unpack_dir=`unpack_dirname $packed`
  [ -d $unpack_dir ] || unpack $packed
  popd
  ln -sfn $dw_dir/$unpack_dir $1
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

function _unlink() {
  [ -L $1 ] && unlink $1
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
    [ -f $dw_dir/$filename ] && continue
    curl -s -L $url -o $dw_dir/$filename &
  done
  wait

  for dep in "${openssh_deps[@]}"; do
    init_lib $dep &
  done
  wait
}

function clean() {
  openssh_related_variable
  for dep in "${openssh_deps[@]}"; do
    _unlink $dep
  done
}

function variable_inject() {
  declare -g a=10
}

function functor_exist() {
  [ `type -t $1` = "function" ] \
    && return 0 \
    || return 1
}

function try_source() {
  [ -f $1 ] && . $1 && return 0
  return 1
}

case $1 in
  clean)
    clean;;
  inject)
    echo $a
    variable_inject
    echo $a;;
esac
