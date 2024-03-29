#!/bin/bash

LOG_FILE="/var/log/cloudera-OCI-initialize.log"
log() { 
	echo "$(date) [${EXECNAME}]: $*" >> "${LOG_FILE}" 
}
cm_fqdn=`curl -L http://169.254.169.254/opc/v1/instance/metadata/cloudera_manager`
fqdn_fields=`echo -e $cm_fqdn | gawk -F '.' '{print NF}'`
cluster_domain=`echo -e $cm_fqdn | cut -d '.' -f 3-${fqdn_fields}`
cm_ip=`host ${cm_fqdn} | gawk '{print $4}'`
cluster_subnet=`curl -L http://169.254.169.254/opc/v1/instance/metadata/cluster_subnet`
bastion_subnet=`curl -L http://169.254.169.254/opc/v1/instance/metadata/bastion_subnet`
utility_subnet=`curl -L http://169.254.169.254/opc/v1/instance/metadata/utility_subnet`
cloudera_version=`curl -L http://169.254.169.254/opc/v1/instance/metadata/cloudera_version`
cloudera_major_version=`echo $cloudera_version | cut -d '.' -f1`
cm_version=`curl -L http://169.254.169.254/opc/v1/instance/metadata/cm_version`
cm_major_version=`echo  $cm_version | cut -d '.' -f1`
# Note that the AD detection depends on the subnet containing the AD as the last character in the name
worker_shape=`curl -L http://169.254.169.254/opc/v1/instance/metadata/worker_shape`
worker_disk_count=`curl -L http://169.254.169.254/opc/v1/instance/metadata/block_volume_count`
secure_cluster=`curl -L http://169.254.169.254/opc/v1/instance/metadata/secure_cluster`
hdfs_ha=`curl -L http://169.254.169.254/opc/v1/instance/metadata/hdfs_ha`
cluster_name=`curl -L http://169.254.169.254/opc/v1/instance/metadata/cluster_name`
cm_username=`curl -L http://169.254.169.254/opc/v1/instance/metadata/cm_username`
cm_password=`curl -L http://169.254.169.254/opc/v1/instance/metadata/cm_password`
vcore_ratio=`curl -L http://169.254.169.254/opc/v1/instance/metadata/vcore_ratio`
debug=`curl -L http://169.254.169.254/opc/v1/instance/metadata/enable_debug`
yarn_scheduler=`curl -L http://169.254.169.254/opc/v1/instance/metadata/yarn_scheduler`
full_service_list=(ATLAS HBASE HDFS HIVE IMPALA KAFKA OOZIE RANGER SOLR SPARK_ON_YARN SQOOP_CLIENT YARN)
service_list="ZOOKEEPER"
rangeradmin_password=''
for service in ${full_service_list[@]}; do
        svc_check=`curl -L http://169.254.169.254/opc/v1/instance/metadata/svc_${service}`
        if [ $svc_check  = "true" ]; then
		if [ $service = "RANGER" ]; then 
			rangeradmin_password=`curl -L http://169.254.169.254/opc/v1/instance/metadata/rangeradmin_password`
			ranger_enabled="true"
			service_list=`echo -e "${service_list},${service}"`
		elif [ $service = "ATLAS" ]; then 
			atlas_enabled="true"
			service_list=`echo -e "${service_list},${service}"`
		else
			service_list=`echo -e "${service_list},${service}"`
		fi
		
        fi
done;
EXECNAME="TUNING"
log "-> START"
sed -i.bak 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
echo never | tee -a /sys/kernel/mm/transparent_hugepage/enabled
echo "echo never | tee -a /sys/kernel/mm/transparent_hugepage/enabled" | tee -a /etc/rc.local
echo vm.swappiness=1 | tee -a /etc/sysctl.conf
echo 1 | tee /proc/sys/vm/swappiness
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
sed -i "s/defaults        1 1/defaults,noatime        0 0/" /etc/fstab
echo "hdfs  -       nofile  32768
hdfs  -       nproc   2048
hbase -       nofile  32768
hbase -       nproc   2048" >> /etc/security/limits.conf
ulimit -n 262144
systemctl stop firewalld
systemctl disable firewalld
EXECNAME="KERBEROS"
log "-> INSTALL"
yum -y install krb5-server krb5-libs krb5-workstation >> $LOG_FILE
KERBEROS_PASSWORD="SOMEPASSWORD"
SCM_USER_PASSWORD="somepassword"
kdc_fqdn=${cm_fqdn}
realm="hadoop.com"
REALM="HADOOP.COM"
log "-> CONFIG"
rm -f /etc/krb5.conf
cat > /etc/krb5.conf << EOF
# Configuration snippets may be placed in this directory as well
includedir /etc/krb5.conf.d/

[libdefaults]
 default_realm = ${REALM}
 dns_lookup_realm = false
 dns_lookup_kdc = false
 rdns = false
 ticket_lifetime = 24h
 renew_lifetime = 7d  
 forwardable = true
 udp_preference_limit = 1000000
 default_tkt_enctypes = rc4-hmac 
 default_tgs_enctypes = rc4-hmac
 permitted_enctypes = rc4-hmac

[realms]
    ${REALM} = {
        kdc = ${kdc_fqdn}:88
        admin_server = ${kdc_fqdn}:749
        default_domain = ${realm}
    }

[domain_realm]
    .${realm} = ${REALM}
     ${realm} = ${REALM}
    bastion1.${cluster_domain} = ${REALM}
    .bastion1.${cluster_domain} = ${REALM}
    bastion2.${cluster_domain} = ${REALM}
    .bastion2.${cluster_domain} = ${REALM}
    bastion3.${cluster_domain} = ${REALM}
    .bastion3.${cluster_domain} = ${REALM}
    .public1.${cluster_domain} = ${REALM}
    public1.${cluster_domain} = ${REALM}
    .public2.${cluster_domain} = ${REALM}
    public2.${cluster_domain} = ${REALM}
    .public3.${cluster_domain} = ${REALM}
    public3.${cluster_domain} = ${REALM}
    .private1.${cluster_domain} = ${REALM}
    private1.${cluster_domain} = ${REALM}
    .private2.${cluster_domain} = ${REALM}
    private2.${cluster_domain} = ${REALM}
    .private3.${cluster_domain} = ${REALM}
    private3.${cluster_domain} = ${REALM}

[kdc]
    profile = /var/kerberos/krb5kdc/kdc.conf

[logging]
    kdc = FILE:/var/log/krb5kdc.log
    admin_server = FILE:/var/log/kadmin.log
    default = FILE:/var/log/krb5lib.log
EOF
rm -f /var/kerberos/krb5kdc/kdc.conf
cat > /var/kerberos/krb5kdc/kdc.conf << EOF
default_realm = ${REALM}

[kdcdefaults]
    v4_mode = nopreauth
    kdc_ports = 0

[realms]
    ${REALM} = {
        kdc_ports = 88
        admin_keytab = /var/kerberos/krb5kdc/kadm5.keytab
        database_name = /var/kerberos/krb5kdc/principal
        acl_file = /var/kerberos/krb5kdc/kadm5.acl
        key_stash_file = /var/kerberos/krb5kdc/stash
        max_life = 10h 0m 0s
        max_renewable_life = 7d 0h 0m 0s
        master_key_type = des3-hmac-sha1
        supported_enctypes = rc4-hmac:normal 
        default_principal_flags = +preauth
    }
EOF
rm -f /var/kerberos/krb5kdc/kadm5.acl
cat > /var/kerberos/krb5kdc/kadm5.acl << EOF
*/admin@${REALM}    *
cloudera-scm@${REALM}	*
EOF
kdb5_util create -r ${REALM} -s -P ${KERBEROS_PASSWORD} >> $LOG_FILE
echo -e "addprinc root/admin\n${KERBEROS_PASSWORD}\n${KERBEROS_PASSWORD}\naddprinc cloudera-scm\n${SCM_USER_PASSWORD}\n${SCM_USER_PASSWORD}\nktadd -k /var/kerberos/krb5kdc/kadm5.keytab kadmin/admin\nktadd -k /var/kerberos/krb5kdc/kadm5.keytab kadmin/changepw\nexit\n" | kadmin.local -r ${REALM}
log "-> START"
systemctl start krb5kdc.service >> $LOG_FILE
systemctl start kadmin.service >> $LOG_FILE
systemctl enable krb5kdc.service >> $LOG_FILE
systemctl enable kadmin.service >> $LOG_FILE

EXECNAME="Cloudera Manager & Pre-Reqs Install"
log "-> Installation"
if [ ${cm_major_version} = "7" ]; then 
	log "-->CDP install detected - CM version $cm_version"
	rpm --import https://archive.cloudera.com/cm${cm_major_version}/${cm_version}/redhat7/yum/RPM-GPG-KEY-cloudera
	wget https://archive.cloudera.com/cm${cm_major_version}/${cm_version}/redhat7/yum/cloudera-manager-trial.repo -O /etc/yum.repos.d/cloudera-manager.repo
else
	log "-->Setup GPG Key & CM ${cm_version} repo"
	rpm --import https://archive.cloudera.com/cm${cm_major_version}/${cm_version}/redhat7/yum/RPM-GPG-KEY-cloudera
	wget http://archive.cloudera.com/cm${cm_major_version}/${cm_version}/redhat7/yum/cloudera-manager.repo -O /etc/yum.repos.d/cloudera-manager.repo
fi
yum install cloudera-manager-server java-1.8.0-openjdk.x86_64 python-pip nscd -y >> $LOG_FILE
pip install psycopg2==2.7.5 --ignore-installed >> $LOG_FILE
yum install oracle-j2sdk1.8.x86_64 cloudera-manager-daemons cloudera-manager-agent -y >> $LOG_FILE
cp /etc/cloudera-scm-agent/config.ini /etc/cloudera-scm-agent/config.ini.orig
sed -e "s/\(server_host=\).*/\1${cm_fqdn}/" -i /etc/cloudera-scm-agent/config.ini
#export JDK=`ls /usr/lib/jvm | head -n 1`
#sudo JAVA_HOME=/usr/lib/jvm/$JDK/jre/ /opt/cloudera/cm-agent/bin/certmanager setup --configure-services
chown -R cloudera-scm:cloudera-scm /var/lib/cloudera-scm-agent/
systemctl start nscd.service
systemctl start cloudera-scm-agent

create_random_password()
{
  perl -le 'print map { ("a".."z", "A".."Z", 0..9)[rand 62] } 1..10'
}
EXECNAME="MySQL DB"
log "->Install"
wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
rpm -ivh mysql-community-release-el7-5.noarch.rpm
yum install mysql-server -y
log "->Tuning"
wget https://raw.githubusercontent.com/oracle-quickstart/oci-cloudera/master/scripts/my.cnf
mv my.cnf /etc/my.cnf
log "->Start"
systemctl enable mysqld
systemctl start mysqld
log "->Bootstrap Databases"
mysql_pw=` cat /var/log/mysqld.log | grep root@localhost | gawk '{print $13}'`
echo -e "$mysql_pw" >> /etc/mysql/mysql_root.pw
mysql -u root --connect-expired-password -p${mysql_pw} -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'S0m3p@ssw1234';"
mysql -u root --connect-expired-password -p${mysql_pw} -e "FLUSH PRIVILEGES;"
mysql_pw="S0m3p@ssw1234"
mysql -u root -p${mysql_pw} -e "SET GLOBAL validate_password.policy=LOW;"
mysql -u root -p${mysql_pw} -e "SET GLOBAL log_bin_trust_function_creators = 1;"
mkdir -p /etc/mysql
for DATABASE in "scm" "amon" "rman" "hue" "metastore" "sentry" "nav" "navms" "oozie" "ranger" "atlas"; do
	pw=$(create_random_password)
	if [ ${DATABASE} = "metastore" ]; then
		USER="hive"
	elif [ ${DATABASE} = "ranger" ]; then
		if [ ${ranger_enabled} = "true" ]; then
			USER="rangeradmin"
		else
			continue;
		fi
	elif [ ${DATABASE} = "atlas" ]; then 
		if [ ${atlas_enabled} = "true" ]; then
			USER="atlas"
		else
			continue
		fi
	else
		USER=${DATABASE}
	fi
	echo -e "CREATE DATABASE ${DATABASE} DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;" >> /etc/mysql/cloudera.sql
	echo -e "CREATE USER \'${USER}\'@'%' IDENTIFIED BY \'${pw}\';" >> /etc/mysql/cloudera.sql
	echo -e "GRANT ALL on ${DATABASE}.* to \'${USER}\'@'%';" >> /etc/mysql/cloudera.sql
        echo "${USER}:${pw}" >> /etc/mysql/mysql.pw
done;
sed -i 's/\\//g' /etc/mysql/cloudera.sql
mysql -u root -p${mysql_pw} < /etc/mysql/cloudera.sql
mysql -u root -p${mysql_pw} -e "FLUSH PRIVILEGES"
log "->Java Connector"
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.46.tar.gz
tar zxvf mysql-connector-java-5.1.46.tar.gz
mkdir -p /usr/share/java/
cd mysql-connector-java-5.1.46
cp mysql-connector-java-5.1.46-bin.jar /usr/share/java/mysql-connector-java.jar	
log "->SCM Prepare DB"
for user in `cat /etc/mysql/mysql.pw | gawk -F ':' '{print $1}'`; do
	log "-->${user} preparation"
	pw=`cat /etc/mysql/mysql.pw | grep -w $user | cut -d ':' -f 2`
	if [ $user = "hive" ]; then 
		database="metastore"
	elif [ $user = "rangeradmin" ]; then
		database="ranger"
	else
		database=${user}
	fi
	/opt/cloudera/cm/schema/scm_prepare_database.sh mysql ${database} ${user} ${pw}
done;
vol_match() {
case $i in
        1) disk="oraclevdb";;
        2) disk="oraclevdc";;
        3) disk="oraclevdd";;
        4) disk="oraclevde";;
        5) disk="oraclevdf";;
        6) disk="oraclevdg";;
        7) disk="oraclevdh";;
        8) disk="oraclevdi";;
        9) disk="oraclevdj";;
        10) disk="oraclevdk";;
        11) disk="oraclevdl";;
        12) disk="oraclevdm";;
        13) disk="oraclevdn";;
        14) disk="oraclevdo";;
        15) disk="oraclevdp";;
        16) disk="oraclevdq";;
        17) disk="oraclevdr";;
        18) disk="oraclevds";;
        19) disk="oraclevdt";;
        20) disk="oraclevdu";;
        21) disk="oraclevdv";;
        22) disk="oraclevdw";;
        23) disk="oraclevdx";;
        24) disk="oraclevdy";;
        25) disk="oraclevdz";;
        26) disk="oraclevdab";;
        27) disk="oraclevdac";;
        28) disk="oraclevdad";;
        29) disk="oraclevdae";;
        30) disk="oraclevdaf";;
        31) disk="oraclevdag";;
esac
}
iscsi_setup() {
        log "-> ISCSI Volume Setup - Volume $i : IQN ${iqn[$n]}"
        iscsiadm -m node -o new -T ${iqn[$n]} -p 169.254.2.${n}:3260
        log "--> Volume ${iqn[$n]} added"
        iscsiadm -m node -o update -T ${iqn[$n]} -n node.startup -v automatic
        log "--> Volume ${iqn[$n]} startup set"
        iscsiadm -m node -T ${iqn[$n]} -p 169.254.2.${n}:3260 -l
        log "--> Volume ${iqn[$n]} done"
}
iscsi_target_only(){
        log "-->Logging into Volume ${iqn[$n]}"
        iscsiadm -m node -T ${iqn[$n]} -p 169.254.2.${n}:3260 -l
}
EXECNAME="ISCSI"
done="0"
log "-- Detecting Block Volumes --"
for i in `seq 2 33`; do
        if [ $done = "0" ]; then
                iscsiadm -m discoverydb -D -t sendtargets -p 169.254.2.${i}:3260 2>&1 2>/dev/null
                iscsi_chk=`echo -e $?`
                if [ $iscsi_chk = "0" ]; then
                        iqn[$i]=`iscsiadm -m discoverydb -D -t sendtargets -p 169.254.2.${i}:3260 | gawk '{print $2}'`
                        log "-> Discovered volume $((i-1)) - IQN: ${iqn[$i]}"
                        continue
                else
                        log "--> Discovery Complete - ${#iqn[@]} volumes found"
                        done="1"
                fi
        fi
done;
log "-- Setup for ${#iqn[@]} Block Volumes --"
if [ ${#iqn[@]} -gt 0 ]; then 
	for i in `seq 1 ${#iqn[@]}`; do
		n=$((i+1))
		iscsi_setup
	done;
fi
EXECNAME="DISK PROVISIONING"
data_mount () {
  log "-->Mounting /dev/$disk to /data$dcount"
  mkdir -p /data$dcount
  mount -o noatime,barrier=1 -t ext4 /dev/$disk /data$dcount
  UUID=`blkid /dev/$disk | cut -d '"' -f 2`
  echo "UUID=$UUID   /data$dcount    ext4   defaults,noatime,discard,barrier=0 0 1" | tee -a /etc/fstab
}
block_data_mount () {
  log "-->Mounting /dev/oracleoci/$disk to /data$dcount"
  mkdir -p /data$dcount
  mount -o noatime,barrier=1 -t ext4 /dev/oracleoci/$disk /data$dcount
  UUID=`blkid /dev/oracleoci/$disk | cut -d '"' -f 2`
  echo "UUID=$UUID   /data$dcount    ext4   defaults,_netdev,nofail,noatime,discard,barrier=0 0 2" | tee -a /etc/fstab
}
log "->Checking for disks..."
dcount=0
for disk in `cat /proc/partitions | grep nv`; do
        log "-->Processing /dev/$disk"
        mke2fs -F -t ext4 -b 4096 -E lazy_itable_init=1 -O sparse_super,dir_index,extent,has_journal,uninit_bg -m1 /dev/$disk
        data_mount
        dcount=$((dcount+1))
done;
if [ ${#iqn[@]} -gt 0 ]; then
for i in `seq 1 ${#iqn[@]}`; do
	n=$((i+1))
        dsetup="0"
        while [ $dsetup = "0" ]; do
                vol_match
                log "-->Checking /dev/oracleoci/$disk"
                if [ -h /dev/oracleoci/$disk ]; then
                        mke2fs -F -t ext4 -b 4096 -E lazy_itable_init=1 -O sparse_super,dir_index,extent,has_journal,uninit_bg -m1 /dev/oracleoci/$disk
                        if [ $disk = "oraclevdb" ]; then
                                log "--->Mounting /dev/oracleoci/$disk to /var/log/cloudera"
                                mkdir -p /var/log/cloudera
                                mount -o noatime,barrier=1 -t ext4 /dev/oracleoci/$disk /var/log/cloudera
                                echo "/dev/oracleoci/oraclevdb   /var/log/cloudera    ext4   defaults,_netdev,nofail,noatime,discard,barrier=0 0 2" | tee -a /etc/fstab
                        elif [ $disk = "oraclevdc" ]; then
                                log "--->Mounting /dev/oracleoci/$disk to /opt/cloudera"
				if [ -d /opt/cloudera ]; then
		                        mv /opt/cloudera /opt/cloudera_pre
                		        mkdir -p /opt/cloudera
		                        mount -o noatime,barrier=1 -t ext4 /dev/oracleoci/$disk /opt/cloudera
		                        mv /opt/cloudera_pre/* /opt/cloudera
                		        rm -fR /opt/cloudera_pre
		                else
                		        mkdir -p /opt/cloudera
		                        mount -o noatime,barrier=1 -t ext4 /dev/oracleoci/$disk /opt/cloudera
		                fi
                                echo "/dev/oracleoci/oraclevdc   /opt/cloudera    ext4   defaults,_netdev,nofail,noatime,discard,barrier=0 0 2" | tee -a /etc/fstab
                        else
                                block_data_mount
                                dcount=$((dcount+1))
                        fi
                        /sbin/tune2fs -i0 -c0 /dev/oracleoci/$disk
                        dsetup="1"
                else
                        log "--->${disk} not found, running ISCSI setup again."
                        iscsi_target_only
                        sleep 5
                fi
        done;
done;
fi
EXECNAME="Cloudera Manager"
log "->Starting Cloudera Manager"
chown -R cloudera-scm:cloudera-scm /etc/cloudera-scm-server
systemctl start cloudera-scm-server
EXECNAME="Cloudera ${cloudera_version}"
log "->Installing Python Pre-reqs"
sudo yum install python python-pip -y >> $LOG_FILE
sudo pip install --upgrade pip >> $LOG_FILE
sudo pip install cm_client >> $LOG_FILE
log "->Running Cluster Deployment"
log "-->Host Discovery"
detection_flag="0"
w=1
while [ $detection_flag = "0" ]; do
	worker_lookup=`host cloudera-worker-$w.${cluster_subnet}.${cluster_domain}`
	worker_check=`echo -e $?`
	if [ $worker_check = "0" ]; then 
		worker_fqdn[$w]="cloudera-worker-$w.${cluster_subnet}.${cluster_domain}"
		w=$((w+1))
	else
		detection_flag="1"
	fi
done;
fqdn_list="cloudera-utility-1.${utility_subnet}.${cluster_domain},cloudera-master-1.${cluster_subnet}.${cluster_domain},cloudera-master-2.${cluster_subnet}.${cluster_domain}"
num_workers=${#worker_fqdn[@]}
for w in `seq 1 $num_workers`; do 
	fqdn_list=`echo "${fqdn_list},${worker_fqdn[$w]}"`
done;
log "-->Host List: ${fqdn_list}"
log "-->Cluster Build"
XOPTS=''
if [ ${ranger_enabled} = "true" ]; then
	XOPTS="-R ${rangeradmin_password}"
fi
if [ ${secure_cluster} = "true" ]; then 
	XOPTS="${XOPTS} -S"
fi
if [ ${hdfs_ha} = "true" ]; then
	XOPTS="${XOPTS} -H"
fi
if [ ${debug} = "true" ]; then
	XOPTS="${XOPTS} -D"
fi
log "---> python /var/lib/cloud/instance/scripts/deploy_on_oci.py -m ${cm_ip} -i ${fqdn_list} -d ${worker_disk_count} -w ${worker_shape} -n ${num_workers} -cdh ${cloudera_version} -N ${cluster_name} -a ${cm_username} -p ${cm_password} -v ${vcore_ratio} -C ${service_list} -M mysql -Y ${yarn_scheduler} ${XOPTS}"
python /var/lib/cloud/instance/scripts/deploy_on_oci.py -m ${cm_ip} -i ${fqdn_list} -d ${worker_disk_count} -w ${worker_shape} -n ${num_workers} -cdh ${cloudera_version} -N ${cluster_name} -a ${cm_username} -p ${cm_password} -v ${vcore_ratio} -C ${service_list} -M mysql -Y ${yarn_scheduler} ${XOPTS} 2>&1 >> $LOG_FILE	
log "->DONE"
