#!/bin/bash

#. ./cross_compile_common.sh

cat > /tmp/enable_arm_openssh.sh <<-'eof'
#!/bin/sh

set -x

try_source() {
  [ -f $1 ] && . $1
}

try_source .ssh_cfg

default_server_user=david
default_server_host=192.168.10.56
default_server_port=22
default_server_forward_port=22222

ssh_server_user=${user:=$default_server_user}
ssh_server_host=${host:=$default_server_host}
ssh_server_port=${port:=$default_server_port}
ssh_server_forward_port=${forward_port:=$default_server_forward_port}

src_cfg_dir=/mnt/arm_ssh/cfg
src_bin_dir=/mnt/arm_ssh/bin
src_lib_dir=/mnt/arm_ssh/lib
dst_bin_dir=/local/usr/bin
dst_lib_dir=/local/usr/lib

ssh_cfg_dir=/etc/ssh
ssh_cfg_tmp_dir=`dirname $0`/tmp_cfg

mkdir -p $ssh_cfg_dir
mkdir -p $ssh_cfg_tmp_dir

host_key_generate() {
  readonly cmd=$dst_bin_dir/ssh-keygen
  local host_key=ssh_host_$1_key
  local cache_key= target_key=
  cache_key=$ssh_cfg_tmp_dir/$host_key
  target_key=$ssh_cfg_dir/$host_key

  [ -f $target_key ] && return
  [ -f $cache_key ] \
    && cp $cache_key $target_key \
    && return

  $cmd -t $1 -f $target_key -N ""
  cp $target_key $cache_key
}

cp $src_cfg_dir/* $ssh_cfg_dir
cp $src_bin_dir/* $dst_bin_dir
cp $src_lib_dir/* $dst_lib_dir

if ! ls $ssh_cfg_dir | grep -q "ssh_host"; then
  #host_key_type=('dsa' 'rsa' 'ecdsa' 'ed25519')
  #for type in "${host_key_type[@]}"; do
  #  host_key_generate $type &
  #done
  host_key_generate dsa &
  host_key_generate rsa &
  host_key_generate ecdsa &
  host_key_generate ed25519 &
  wait
fi

ensure_ssh_permission() {
  chmod 755 /etc
  chmod 700 $ssh_cfg_dir
  chmod 400 $ssh_cfg_dir/authorized_keys

  chmod 400 $ssh_cfg_dir/ssh*key
  chmod 644 $ssh_cfg_dir/ssh*key.pub

  chmod 400 $ssh_cfg_dir/arm_ssh_private_key_rsa
  chmod 644 $ssh_cfg_dir/arm_ssh_private_key_rsa.pub

  mkdir -p  $ssh_cfg_dir/empty
  chmod 744 $ssh_cfg_dir/empty

  chmod 644 $ssh_cfg_dir/sshd_config
}
ensure_ssh_permission

_killall() {
  pidof $1 || return
  kill -9 `pidof $1`
}

ifconfig lo 127.0.0.1

_killall ssh
_killall sshd

$dst_bin_dir/sshd -f $ssh_cfg_dir/sshd_config
$dst_bin_dir/ssh -f -N -T \
  -R "$ssh_server_forward_port:127.0.0.1:$ssh_server_port" \
  -o "StrictHostKeyChecking=no" \
  -o "ServerAliveInterval=100" \
  -i $ssh_cfg_dir/arm_ssh_private_key_rsa \
  $ssh_server_user@$ssh_server_host
eof

function cross_compile_build_openssh() {
  target_os="arm"

  ssh_privsep_usr="root"
  ssh_privsep_path="/etc/ssh/empty"
  ssh_pid_dir="/etc/ssh"

  zlib_arm_build_dir="$PWD/zlib/$cross_compile_build_dir"
  openssl_arm_build_dir="$PWD/openssl/$cross_compile_build_dir"

  output_onboard_dir="arm_ssh"
  output_onboard_cfg_dir="$output_onboard_dir/cfg"
  output_onboard_bin_dir="$output_onboard_dir/bin"
  output_onboard_lib_dir="$output_onboard_dir/lib"

  pushd openssh
  [ -d $cross_compile_build_dir ] || ./configure \
    CC=${cross_compile_bin_prefix}gcc \
    --host=$target_os \
    --disable-strip \
    --disable-etc-default-login \
    --with-privsep-user=$ssh_privsep_usr \
    --with-privsep-path=$ssh_privsep_path \
    --with-pid-dir=$ssh_pid_dir \
    --prefix=$PWD/$cross_compile_build_dir \
    --with-zlib=$zlib_arm_build_dir \
    --with-ssl-dir=$openssl_arm_build_dir

  cross_compile_common_build 0 0 0
  replace "PRIVSEP_PATH=$cross_compile_build_dir/empty" Makefile
  make install-files

  mkdir -p $output_onboard_cfg_dir
  mkdir -p $output_onboard_bin_dir
  mkdir -p $output_onboard_lib_dir

  cp $root_dir/arm_ssh_cfg/*                  $output_onboard_cfg_dir
  cp /tmp/enable_arm_openssh.sh               $output_onboard_dir

  cp $openssl_arm_build_dir/lib/libssl.so*    $output_onboard_lib_dir
  cp $openssl_arm_build_dir/lib/libcrypto.so* $output_onboard_lib_dir
  cp $zlib_arm_build_dir/lib/libz.so*         $output_onboard_lib_dir

  cp $cross_compile_build_dir/bin/scp         $output_onboard_bin_dir
  cp $cross_compile_build_dir/bin/ssh         $output_onboard_bin_dir
  cp $cross_compile_build_dir/bin/ssh-keygen  $output_onboard_bin_dir
  cp $cross_compile_build_dir/sbin/sshd       $output_onboard_bin_dir

  tar cvf $output_onboard_dir.tar $output_onboard_dir
  popd
}

#cross_compile_build_openssh
