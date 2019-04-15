#!/bin/bash

. ./cross_compile_common.sh

cat > /tmp/enable_arm_openssh.sh <<-'eof'
#!/bin/sh

src_cfg_dir=/mnt/arm_ssh/cfg
src_bin_dir=/mnt/arm_ssh/bin
src_lib_dir=/mnt/arm_ssh/lib
dst_bin_dir=/local/usr/bin
dst_lib_dir=/local/usr/lib

ssh_cfg_dir=/etc/ssh
mkdir -p $ssh_cfg_dir

if ! ls $dst_lib_dir | grep qE "libssl|libcrypto|libz"; then
  cp $src_cfg_dir/* $ssh_cfg_dir
  cp $src_bin_dir/* $dst_bin_dir
  cp $src_lib_dir/* $dst_lib_dir
fi

if ! ls $ssh_cfg_dir | grep -q "ssh_host"; then
  $dst_bin_dir/ssh-keygen -t dsa     -f $ssh_cfg_dir/ssh_host_dsa_key     -N ""
  $dst_bin_dir/ssh-keygen -t rsa     -f $ssh_cfg_dir/ssh_host_rsa_key     -N ""
  $dst_bin_dir/ssh-keygen -t ecdsa   -f $ssh_cfg_dir/ssh_host_ecdsa_key   -N ""
  $dst_bin_dir/ssh-keygen -t ed25519 -f $ssh_cfg_dir/ssh_host_ed25519_key -N ""
fi

update_ssh_permission() {
  chmod 700 /etc
  chmod 700 $ssh_cfg_dir
  chmod 400 $ssh_cfg_dir/authorized_keys

  chmod 400 $ssh_cfg_dir/ssh*key
  chmod 644 $ssh_cfg_dir/ssh*key.pub

  chmod 400 $ssh_cfg_dir/arm_ssh_private_key_rsa
  chmod 644 $ssh_cfg_dir/arm_ssh_private_key_rsa.pub

  mkdir -p  $ssh_cfg_dir/empty
  chmod 744 $ssh_cfg_dir/empty
}
update_ssh_permission

ifconfig lo 127.0.0.1

$dst_bin_dir/sshd -f $ssh_cfg_dir/sshd_config
$dst_bin_dir/ssh -f -N -T \
-R "22222:127.0.0.1:22" \
-o "StrictHostKeyChecking=no" \
-o "ServerAliveInterval=100" \
-i $ssh_cfg_dir/arm_ssh_private_key_rsa \
david@192.168.1.101
eof

function cross_compile_build_openssh() {
  init_lib openssh
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
  ./configure\
    CC=${cross_compile_bin_prefix}gcc\
    --host=$target_os\
    --disable-strip\
    --disable-etc-default-login\
    --with-privsep-user=$ssh_privsep_usr\
    --with-privsep-path=$ssh_privsep_path\
    --with-pid-dir=$ssh_pid_dir\
    --prefix=$PWD/$cross_compile_build_dir\
    --with-zlib=$zlib_arm_build_dir\
    --with-ssl-dir=$openssl_arm_build_dir

  cross_compile_common_build 0 0 0
  make install-files

  mkdir -p $output_onboard_cfg_dir
  mkdir -p $output_onboard_bin_dir
  mkdir -p $output_onboard_lib_dir

  cp ../arm_ssh_cfg/*                         $output_onboard_cfg_dir
  cp /tmp/enable_arm_openssh.sh               $output_onboard_dir

  cp $openssl_arm_build_dir/lib/libssl.so*    $output_onboard_lib_dir
  cp $openssl_arm_build_dir/lib/libcrypto.so* $output_onboard_lib_dir
  cp $zlib_arm_build_dir/lib/libz.so*         $output_onboard_lib_dir

  cp $cross_compile_build_dir/bin/scp         $output_onboard_bin_dir
  cp $cross_compile_build_dir/bin/ssh         $output_onboard_bin_dir
  cp $cross_compile_build_dir/bin/ssh-keygen  $output_onboard_bin_dir
  cp $cross_compile_build_dir/sbin/sshd       $output_onboard_bin_dir

  tar cvf $output_onboard_dir.tar ${output_onboard_dir}
  cp $output_onboard_dir.tar ..
  popd
}

#cross_compile_build_openssh
