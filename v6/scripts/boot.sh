#!/bin/bash

LOG_FILE="/var/log/cloudera-OCI-initialize.log"

## logs everything to the $LOG_FILE
log() {
  echo "$(date) [${EXECNAME}]: $*" >> "${LOG_FILE}"
}


EXECNAME="TUNING"
log "->TUNING START"
#
# HOST TUNINGS
# 

## Modify resolv.conf to ensure DNS lookups work
rm -f /etc/resolv.conf
echo "search public1.cdhvcn.oraclevcn.com public2.cdhvcn.oraclevcn.com public3.cdhvcn.oraclevcn.com private1.cdhvcn.oraclevcn.com private2.cdhvcn.oraclevcn.com private3.cdhvcn.oraclevcn.com bastion1.cdhvcn.oraclevcn.com bastion2.cdhvcn.oraclevcn.com bastion3.cdhvcn.oraclevcn.com" > /etc/resolv.conf
echo "nameserver 169.254.169.254" >> /etc/resolv.conf

## Install Java
yum install java-1.8.0-openjdk.x86_64 -y

## Disable Transparent Huge Pages
echo never | tee -a /sys/kernel/mm/transparent_hugepage/enabled
echo "echo never | tee -a /sys/kernel/mm/transparent_hugepage/enabled" | tee -a /etc/rc.local

## Set vm.swappiness to 1
echo vm.swappiness=0 | tee -a /etc/sysctl.conf
echo 0 | tee /proc/sys/vm/swappiness

## Tune system network performance
echo net.ipv4.tcp_timestamps=0 >> /etc/sysctl.conf
echo net.ipv4.tcp_sack=1 >> /etc/sysctl.conf
echo net.core.rmem_max=4194304 >> /etc/sysctl.conf
echo net.core.wmem_max=4194304 >> /etc/sysctl.conf
echo net.core.rmem_default=4194304 >> /etc/sysctl.conf
echo net.core.wmem_default=4194304 >> /etc/sysctl.conf
echo net.core.optmem_max=4194304 >> /etc/sysctl.conf
echo net.ipv4.tcp_rmem="4096 87380 4194304" >> /etc/sysctl.conf
echo net.ipv4.tcp_wmem="4096 65536 4194304" >> /etc/sysctl.conf
echo net.ipv4.tcp_low_latency=1 >> /etc/sysctl.conf

## Tune File System options
sed -i "s/defaults        1 1/defaults,noatime        0 0/" /etc/fstab

## Enable root login via SSH key
cp /root/.ssh/authorized_keys /root/.ssh/authorized_keys.bak
cp /home/opc/.ssh/authorized_keys /root/.ssh/authorized_keys

## Set Limits
echo "hdfs  -       nofile  32768
hdfs  -       nproc   2048
hbase -       nofile  32768
hbase -       nproc   2048" >> /etc/security/limits.conf
ulimit -n 262144

## Post Tuning Execution Below

#
# DISK SETUP
#

EXECNAME="SLEEP"
## SLEEP HERE - GIVE TIME FOR BLOCK VOLUMES TO ATTACH
log "->SLEEP"
sleep 120 

## Look for all ISCSI devices in sequence, finish on first failure
EXECNAME="ISCSI"
v="0"
done="0"
log "-- Mapping Block Volumes --"
for i in `seq 2 33`; do
  if [ $done = "0" ]; then
    iscsiadm -m discoverydb -D -t sendtargets -p 169.254.2.$i:3260 2>&1 2>/dev/null
    iscsi_chk=`echo -e $?`
    if [ $iscsi_chk = "0" ]; then
      iqn=`iscsiadm -m discoverydb -D -t sendtargets -p 169.254.2.$i:3260 | gawk '{print $2}'` 
      log "-> Success for volume $((i-1)) - IQN: $iqn"
      log "-> Finishing volume setup"
      iscsiadm -m node -o new -T $iqn -p 169.254.2.$i:3260
      iscsiadm -m node -o update -T $iqn -n node.startup -v automatic
      iscsiadm -m node -T $iqn -p 169.254.2.$i:3260 -l
      v=$((v+1))
      continue
    else
      log "--> Completed - $((i-2)) volumes found"
      done="1"
    fi
  fi
done;

EXECNAME="boot.sh - DISK PROVISIONING"
#
# Disk Setup uses drives /dev/sdb and /dev/sdc for statically mapped Cloudera partitions (logs, parcels)
# If customizing your Terraform Templates - be sure to pay attention here to ensure proper mounts are presented
#
## Primary Disk Mounting Function
data_mount () {
  log "-->Mounting /dev/$disk to /data$dcount"
  mkdir -p /data$dcount
  mount -o noatime,barrier=1 -t ext4 /dev/$disk /data$dcount
  UUID=`lsblk -no UUID /dev/$disk`
  echo "UUID=$UUID   /data$dcount    ext4   defaults,noatime,discard,barrier=0 0 1" | tee -a /etc/fstab
}

block_data_mount () {
  log "-->Mounting /dev/oracleoci/$disk to /data$dcount"
  mkdir -p /data$dcount
  mount -o noatime,barrier=1 -t ext4 /dev/oracleoci/$disk /data$dcount
  UUID=`lsblk -no UUID /dev/oracleoci/$disk`
  echo "UUID=$UUID   /data$dcount    ext4   defaults,_netdev,nofail,noatime,discard,barrier=0 0 2" | tee -a /etc/fstab
}

EXECNAME="DISK SETUP"
## Check for x>0 devices
log "->Checking for disks..."
nvcount="0"
bvcount="0"
## Execute - will format all devices except sda for use as data disks in HDFS
dcount=0
for disk in `ls /dev/ | grep nvme`; do
	log "-->Processing /dev/$disk"
  	mke2fs -F -t ext4 -b 4096 -E lazy_itable_init=1 -O sparse_super,dir_index,extent,has_journal,uninit_bg -m1 /dev/$disk
    	data_mount
	dcount=$((dcount+1))
done;
for disk in `ls /dev/oracleoci/ | grep -ivw 'oraclevda' | grep -ivw 'oraclevda[1-3]'`; do 
	log "-->Processing /dev/oracleoci/$disk"
	mke2fs -F -t ext4 -b 4096 -E lazy_itable_init=1 -O sparse_super,dir_index,extent,has_journal,uninit_bg -m1 /dev/oracleoci/$disk
	if [ $disk = "oraclevdb" ]; then
                log "-->Mounting /dev/oracleoci/$disk to /var/log/cloudera"
                mkdir -p /var/log/cloudera
                mount -o noatime,barrier=1 -t ext4 /dev/oracleoci/$disk /var/log/cloudera
                UUID=`lsblk -no UUID /dev/oracleoci/$disk`
                echo "UUID=$UUID   /var/log/cloudera    ext4   defaults,_netdev,nofail,noatime,discard,barrier=0 0 2" | tee -a /etc/fstab
	elif [ $disk = "oraclevdc" ]; then
		log "-->Mounting /dev/oracleoci/$disk to /opt/cloudera"
		mkdir -p /opt/cloudera
		mount -o noatime,barrier=1 -t ext4 /dev/oracleoci/$disk /opt/cloudera
		UUID=`lsblk -no UUID /dev/oracleoci/$disk`
		echo "UUID=$UUID   /opt/cloudera    ext4   defaults,_netdev,nofail,noatime,discard,barrier=0 0 2" | tee -a /etc/fstab
	else
		block_data_mount
                dcount=$((dcount+1))
  	fi
	/sbin/tune2fs -i0 -c0 /dev/oracleoci/$disk
done;
EXECNAME="END"
log "->DONE"
