#!/bin/bash
## cloud-init bootstrap script
## Stop SSHD to prevent remote execution during this process
systemctl stop sshd
## set speedup="1" to bypass host reboot - should set selinux to permissive mode allowing for faster deployment
speedup="1"
if [ $speedup = "0" ]; then
  if [ -f /etc/selinux/config ]; then
    selinuxchk=`sudo cat /etc/selinux/config | grep enforcing`
    selinux_chk=`echo -e $?`
    if [ $selinux_chk = "0" ]; then
      sed -i.bak 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
      reboot
    fi
  fi
elif [ $speedup = "1" ]; then
  if [ -f /etc/selinux/config ]; then
    selinuxchk=`sudo cat /etc/selinux/config | grep enforcing`
    selinux_chk=`echo -e $?`
    if [ $selinux_chk = "0" ]; then
      sed -i.bak 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
      setenforce 0
    fi
  fi
fi

## Custom Boot Volume Extension
yum -y install cloud-utils-growpart
yum -y install gdisk
growpart /dev/sda 3
echo "0" > /home/opc/.done
reboot
