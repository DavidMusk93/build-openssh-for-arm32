# build-openssh-for-arm32
If you have an arm board (root), it is convenient to login/transfer-data by ssh.

## My Env (Step 1: Download Toolchain & Config)
* `host`: Ubuntu 16.04
* `cross build toolchain`: gcc-linaro-5.4.1-2017.05-x86_64_arm-linux-gnueabihf (unpack to /opt/toolchian for me)

## Libraries Version (Step 2: Download Relevant Libraries)
* `zlib` (1.2.11)
* `openssl` (1.1.1b)
* `openssh` (7.9p1, downloaded from https://www.complang.tuwien.ac.at/doc/openssh-server/faq.html)

## Step 3: Generate key & authorized_keys
```
$ ssh-keygen -f ./arm_ssh_cfg/arm_ssh_private_key_rsa

#to tunnel with host without password on board
$ cat ./arm_ssh_cfg/arm_ssh_private_key_rsa.pub >> ~/.ssh/authorized_keys

#to login in board without password on host
$ cat path-to-your-public-key > ./arm_ssh_cfg/authorized_keys
```

## Step 4: Build on Host
```
$ bash run.sh
#arm_ssh.tar would be generated
```

## Step 5: Enable SSH on Board
```
#copy arm_ssh.tar to board(/mnt) with tftp/nfs/sd-card
#login in board with telnet/serial
$ cd /mnt 
$ busybox tar -xvf arm_ssh.tar
$ nohup sh /mnt/arm_ssh/enable_arm_openssh.sh &
```

**Note** in enable_arm_openssh.sh:
1. my hostname is `david`
2. my host ip is `192.168.1.101`, make sure your host and board on the same net
3. the tunnel port is `22222`

## Step 6: Try to Communicate with Your Board by SSH
```
#login
$ ssh root@your-board-ip -i path-to-your-private-key

#ssh-tunnel
$ ssh -p 22222 root@localhost -i path-to-your-private-key

#scp (not work on board)
$ scp -r file/directory root@your-board-ip:path-on-board -i path-to-your-private-key
$ scp -r root@your-board-ip:file/directory-on-board path-on-host -i path-to-your-private-key
```

Enjoy it!
