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
cdh_version=`curl -L http://169.254.169.254/opc/v1/instance/metadata/cdh_version`
cdh_major_version=`echo $cdh_version | cut -d '.' -f1`
cm_version=`curl -L http://169.254.169.254/opc/v1/instance/metadata/cm_version`
cm_major_version=`echo  $cm_version | cut -d '.' -f1`
worker_shape=`curl -L http://169.254.169.254/opc/v1/instance/metadata/worker_shape`
worker_disk_count=`curl -L http://169.254.169.254/opc/v1/instance/metadata/block_volume_count`
secure_cluster=`curl -L http://169.254.169.254/opc/v1/instance/metadata/secure_cluster`
hdfs_ha=`curl -L http://169.254.169.254/opc/v1/instance/metadata/hdfs_ha`
cluster_name=`curl -L http://169.254.169.254/opc/v1/instance/metadata/cluster_name`
EXECNAME="TUNING"
log "-> START"
sed -i.bak 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
echo never | tee -a /sys/kernel/mm/transparent_hugepage/enabled
echo "echo never | tee -a /sys/kernel/mm/transparent_hugepage/enabled" | tee -a /etc/rc.local
echo vm.swappiness=0 | tee -a /etc/sysctl.conf
echo 0 | tee /proc/sys/vm/swappiness
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
cloudera-scm@${REALM}   *
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
rpm --import https://archive.cloudera.com/cdh${cm_major_version}/${cm_version}/redhat7/yum//RPM-GPG-KEY-cloudera
wget http://archive.cloudera.com/cm${cm_major_version}/${cm_version}/redhat7/yum/cloudera-manager.repo -O /etc/yum.repos.d/cloudera-manager.repo
yum install cloudera-manager-server java-1.8.0-openjdk.x86_64 python-pip -y >> $LOG_FILE
pip install psycopg2==2.7.5 --ignore-installed >> $LOG_FILE
yum install oracle-j2sdk1.8.x86_64 cloudera-manager-daemons cloudera-manager-agent -y >> $LOG_FILE
cp /etc/cloudera-scm-agent/config.ini /etc/cloudera-scm-agent/config.ini.orig
sed -e "s/\(server_host=\).*/\1${cm_fqdn}/" -i /etc/cloudera-scm-agent/config.ini
chown -R cloudera-scm:cloudera-scm /var/lib/cloudera-scm-agent/
systemctl start cloudera-scm-agent
install_postgres(){
yum install postgreql-server -y
EXECNAME="Postgresql Bootstrap"
CURRENT_VERSION_MARKER='OCI_1'
SLEEP_INTERVAL=5
}
stop_db()
{
  systemctl stop postgresql
}
fail_or_continue()
{
  local RET=$1
  local STR=$2
  if [[ $RET -ne 0 ]]; then
    stop_db
    if [[ -z $STR ]]; then
      STR="--> Error $RET"
    fi
    log "$STR, giving up"
    log "------- initialize-postgresql.sh failed -------"
    exit "$RET"
  fi
}
create_database()
{
  local DB_CMD="sudo -u postgres psql"
  local DBNAME=$1
  local PW=$2
  local ROLE=$DBNAME
  if ! [ -z "$3" ];then
    local ROLE=$3
    echo "$3, $ROLE"
  fi
  echo "$ROLE"
  echo "CREATE ROLE $ROLE LOGIN PASSWORD '$PW';"
  $DB_CMD --command "CREATE ROLE $ROLE LOGIN PASSWORD '$PW';"
  fail_or_continue $? "Unable to create database role $ROLE"
  echo "CREATE DATABASE $DBNAME OWNER $ROLE;"
  $DB_CMD --command "CREATE DATABASE $DBNAME OWNER $ROLE;"
  fail_or_continue $? "Unable to create database $DBNAME"
}
db_exists()
{
  grep -q -s -e "^$1$" "$DB_LIST_FILE"
}
create_random_password()
{
  perl -le 'print map { ("a".."z", "A".."Z", 0..9)[rand 62] } 1..10'
}
create_scm_db()
{
  if db_exists scm; then
    return 0
  fi

  local PW=$1
  create_database scm "$PW"

  orig_umask=$(umask)
  umask 0077
  echo "Creating SCM configuration file: $DB_PROP_FILE"
  cat > "$DB_PROP_FILE" << EOF
com.cloudera.cmf.db.type=postgresql
com.cloudera.cmf.db.host=localhost:$DB_PORT
com.cloudera.cmf.db.name=scm
com.cloudera.cmf.db.user=scm
com.cloudera.cmf.db.password=$PW
EOF

  umask "$orig_umask"
  fail_or_continue $? "Error creating file $DB_PROP_FILE"
  echo "Created db properties file $DB_PROP_FILE"
  echo scm >> "$DB_LIST_FILE"
}
create_hive_metastore()
{
  local role='HIVEMETASTORESERVER'
  local db='metastore'
  local hive='hive'
  if db_exists $db; then
    return 0
  fi

  echo "Creating DB $db for role $role"
  local pw
  pw=$(create_random_password)
  create_database "$db" "$pw" "$hive"

  echo "host    $db $hive  0.0.0.0/0   md5" >> "$DATA_DIR"/pg_hba.conf
  if [[ ! -f $MGMT_DB_PROP_FILE ]]; then
    orig_umask=$(umask)
    umask 0077
    touch $MGMT_DB_PROP_FILE
    umask "$orig_umask"
    fail_or_continue $? "Error creating file $MGMT_DB_PROP_FILE"
  fi
  local PREFIX="com.cloudera.cmf.$role.db"
  cat >> "$MGMT_DB_PROP_FILE" <<EOF
$PREFIX.type=postgresql
$PREFIX.host=$DB_HOSTPORT
$PREFIX.name=$db
$PREFIX.user=$hive
$PREFIX.password=$pw
EOF
  fail_or_continue $? "Error updating file $MGMT_DB_PROP_FILE"
  echo "host    $db   $hive   0.0.0.0/0   md5" >> "$DATA_DIR"/pg_hba.conf
  echo "Created DB for role $role"
  echo "$db" >> "$DB_LIST_FILE"
}
create_mgmt_role_db()
{
  local role=$1
  local db=$2
  if db_exists "$db"; then
    return 0
  fi
  echo "Creating DB $db for role $role"
  local pw
  pw=$(create_random_password)
  create_database "$db" "$pw"
  if [[ ! -f $MGMT_DB_PROP_FILE ]]; then
    orig_umask=$(umask)
    umask 0077
    touch $MGMT_DB_PROP_FILE
    umask "$orig_umask"
    fail_or_continue $? "Error creating file $MGMT_DB_PROP_FILE"
  fi
  local PREFIX="com.cloudera.cmf.$role.db"
  cat >> "$MGMT_DB_PROP_FILE" <<EOF
$PREFIX.type=postgresql
$PREFIX.host=$DB_HOSTPORT
$PREFIX.name=$db
$PREFIX.user=$db
$PREFIX.password=$pw
EOF
  fail_or_continue $? "Error updating file $MGMT_DB_PROP_FILE"
  echo "host    $db   $db   0.0.0.0/0   md5" >> "$DATA_DIR"/pg_hba.conf
  log "-->Created DB for role $role"
  echo "$db" >> "$DB_LIST_FILE"
}
pg_hba_contains()
{
  grep -q -s -e "^$1$" "$DATA_DIR"/pg_hba.conf
}
configure_remote_connections()
{
  local FIRSTLINE="# block remote access for admin user"
  local SECONDLINE="host    all    postgres 0.0.0.0/0 reject"
  local THIRDLINE="# enable remote access for other users"
  local FOURTHLINE="host    sameuser all  0.0.0.0/0   md5"
  if pg_hba_contains "$FIRSTLINE"; then
    return 0
  fi
  echo "$FIRSTLINE" >> "$DATA_DIR"/pg_hba.conf
  echo "$SECONDLINE" >> "$DATA_DIR"/pg_hba.conf
  echo "$THIRDLINE" >> "$DATA_DIR"/pg_hba.conf
  echo "$FOURTHLINE" >> "$DATA_DIR"/pg_hba.conf
  log "-->Enabled remote connections"
}
get_system_ram()
{
  local free_output
  free_output=$(free -b | grep Mem)
  local regex="Mem:[[:space:]]+([[:digit:]]+)"
  if [[ $free_output =~ $regex ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    fail_or_continue 1 "Unable to find amount of RAM on the system"
  fi
}
get_shared_buffers()
{
  local ram
  ram=$(get_system_ram)
  local shmmax
  shmmax=$(cat /proc/sys/kernel/shmmax)
  local THIRTY_TWO_MB=$((32 * 1024 * 1024))
  local EIGHT_GB=$((8 * 1024 * 1024 * 1024))
  local SIXTEEN_GB=$((16 * 1024 * 1024 * 1024))
  local shared_buffer;
  if [ ${#shmmax} -gt 11 ]; then
    shmmax=$SIXTEEN_GB
  fi
  if [ "$shmmax" -eq "$THIRTY_TWO_MB" ]; then
    let "shared_buffer=shmmax / 4"
    let "shared_buffer=shared_buffer / (8192 + 208)"
    echo "shared_buffers=$shared_buffer"
  elif [ "$shmmax" -gt "$THIRTY_TWO_MB" ]; then
    let "shared_buffer=shmmax / 2"
    if [ "$shared_buffer" -gt "$EIGHT_GB" ]; then
      shared_buffer=$EIGHT_GB
    fi
    let "quarter_of_ram=ram / 4"
    if [ "$shared_buffer" -gt "$quarter_of_ram" ]; then
      shared_buffer=$quarter_of_ram
    fi
    let "shared_buffer=shared_buffer / (8192 + 208)"
    echo "shared_buffers=$shared_buffer"
  fi
}
get_postgresql_major_version()
{
  local psql_output
  psql_output=$(psql --version)
  local regex
  regex="^psql \(PostgreSQL\) ([[:digit:]]+)\..*"

  if [[ $psql_output =~ $regex ]]; then
    echo "${BASH_REMATCH[1]}"
  fi
}
get_standard_conforming_strings()
{
  local psql_version
  psql_version=$(get_postgresql_major_version)
  if [[ $psql_version -gt 8 ]]; then
    echo "# This is needed to make Hive work with Postgresql 9.1 and above\\"
    echo "# See OPSAPS-11795\\"
    echo "standard_conforming_strings=off"
  fi
}
configure_postgresql_conf()
{
  local CONF_FILE="$1"
  local IS_UPGRADE="$2"
  sed -e '/^listen_addresses\s*=/d' -i "$CONF_FILE"
  sed -e '/^max_connections\s*=/d' -i "$CONF_FILE"
  sed -e '/^shared_buffers\s*=/d' -i "$CONF_FILE"
  sed -e '/^standard_conforming_strings\s*=/d' -i "$CONF_FILE"
  local TMPFILE
  TMPFILE=$(mktemp /tmp/XXXXXXXX)
  cat "$CONF_FILE" >> "$TMPFILE"
  echo Adding configs
  sed -i "2a # === $CURRENT_VERSION_MARKER at $NOW" "$TMPFILE"
  sed -i "3a port = $DB_PORT" "$TMPFILE"
  sed -i "4a listen_addresses = '*'" "$TMPFILE"
  sed -i "5a max_connections = 500" "$TMPFILE"
  local LINE_NUM=6
  local SHARED_BUFFERS
  SHARED_BUFFERS="$(get_shared_buffers)"
  if [ -n "${SHARED_BUFFERS}" ]; then
    sed -i "${LINE_NUM}a ${SHARED_BUFFERS}" "$TMPFILE"
    LINE_NUM=7
  fi
  local SCS
  SCS="$(get_standard_conforming_strings)"
  if [ -n "${SCS}" ]; then
    sed -i "${LINE_NUM}a ${SCS}" "$TMPFILE"
  fi
  cat "$TMPFILE" > "$CONF_FILE"
}
wait_for_db_server_to_start()
{
  log "Wait for DB server to start"
  i=0
  until [ $i -ge 5 ]
  do
    i=$((i+1))
    sudo -u postgres psql -l && break
    sleep "${SLEEP_INTERVAL}"
  done
  if [ $i -ge 5 ]; then
    log "DB failed to start within $((i * SLEEP_INTERVAL)) seconds, exit with status 1"
    log "------- Postgresql startup failed -------"
    exit 1
  fi
}
install_postgres
log "------- Begin Postgresql Setup  -------"
echo 'LC_ALL="en_US.UTF-8"' >> /etc/locale.conf
log "-- Running Postgresql initdb --"
su -l postgres -c "postgresql-setup initdb"
log "-- Starting Postgresql --"
systemctl start postgresql
SCM_PWD=$(create_random_password)
DATA_DIR=/var/lib/pgsql/data
DB_HOST=$(hostname -f)
DB_PORT=${DB_PORT:-5432}
DB_HOSTPORT="$DB_HOST:$DB_PORT"
DB_PROP_FILE=/etc/cloudera-scm-server/db.properties
MGMT_DB_PROP_FILE=/etc/cloudera-scm-server/db.mgmt.properties
DB_LIST_FILE=$DATA_DIR/scm.db.list
NOW=$(date +%Y%m%d-%H%M%S)
log "-- Configuring Postgresql --"
configure_postgresql_conf $DATA_DIR/postgresql.conf 0
echo "# Accept connections from all hosts" >> $DATA_DIR/pg_hba.conf
sed -i '/host.*127.*ident/i \
  host    all         all         127.0.0.1/32          md5  \ ' $DATA_DIR/pg_hba.conf
/sbin/chkconfig postgresql on
log "-- Restarting Postgresql --"
systemctl restart postgresql
wait_for_db_server_to_start
log "-- Postgres DB Started --"
log "-- Setting up SCM DB --"
create_scm_db "$SCM_PWD"
log "-- Setting up additional CM DBs --"
create_mgmt_role_db ACTIVITYMONITOR amon
create_mgmt_role_db REPORTSMANAGER rman
create_mgmt_role_db NAVIGATOR nav
create_mgmt_role_db NAVIGATORMETASERVER navms
create_mgmt_role_db OOZIE oozie
create_mgmt_role_db HUE	hue
create_mgmt_role_db SENTRY sentry
log "-- Creating HIVE Metastore --"
create_hive_metastore
log "-- Running SCM DB Bootstrap --"
/opt/cloudera/cm/schema/scm_prepare_database.sh postgresql scm scm "$SCM_PWD" >> "${LOG_FILE}" 2>&1
log "-- Configuring Remote Connections --"
configure_remote_connections
log "-- Restarting Postgresql to refresh config --"
systemctl restart postgresql
wait_for_db_server_to_start
log "-- DONE --"
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
                                UUID=`lsblk -no UUID /dev/oracleoci/$disk`
                                echo "UUID=$UUID   /var/log/cloudera    ext4   defaults,_netdev,nofail,noatime,discard,barrier=0 0 2" | tee -a /etc/fstab
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
                                UUID=`lsblk -no UUID /dev/oracleoci/$disk`
                                echo "UUID=$UUID   /opt/cloudera    ext4   defaults,_netdev,nofail,noatime,discard,barrier=0 0 2" | tee -a /etc/fstab
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
EXECNAME="Cloudera Enterprise Data Hub"
log "->Installing Python Pre-reqs"
sudo yum install python python-pip -y >> $LOG_FILE
sudo pip install --upgrade pip >> $LOG_FILE
sudo pip install cm_client >> $LOG_FILE
log "->Running Cluster Deployment"
log "-->Host Discovery"
detection_flag="0"
w=1
while [ $detection_flag = "0" ]; do
        worker_lookup=`host cdh-worker-$w.${cluster_subnet}.${cluster_domain}`
        worker_check=`echo -e $?`
        if [ $worker_check = "0" ]; then
                worker_fqdn[$w]="cdh-worker-$w.${cluster_subnet}.${cluster_domain}"
                w=$((w+1))
        else
                detection_flag="1"
        fi
done;
fqdn_list="cdh-utility-1.${utility_subnet}.${cluster_domain},cdh-master-1.${cluster_subnet}.${cluster_domain},cdh-master-2.${cluster_subnet}.${cluster_domain}"
num_workers=${#worker_fqdn[@]}
for w in `seq 1 $num_workers`; do
        fqdn_list=`echo "${fqdn_list},${worker_fqdn[$w]}"`
done;
log "-->Host List: ${fqdn_list}"
log "-->Cluster Build"
if [ $secure_cluster = "true" ]; then
        if [ $hdfs_ha = "true" ]; then
                log "---> python /var/lib/cloud/instance/scripts/deploy_on_oci.py -S -H -m ${cm_ip} -i ${fqdn_list} -d ${worker_disk_count} -w ${worker_shape} -n ${num_workers} -cdh ${cdh_version} -N ${cluster_name}"
                python /var/lib/cloud/instance/scripts/deploy_on_oci.py -S -H -m ${cm_ip} -i ${fqdn_list} -d ${worker_disk_count} -w ${worker_shape} -n ${num_workers} -cdh ${cdh_version} -N ${cluster_name} 2>&1 1>> $LOG_FILE
        else
                log "---> python /var/lib/cloud/instance/scripts/deploy_on_oci.py -S -m ${cm_ip} -i ${fqdn_list} -d ${worker_disk_count} -w ${worker_shape} -n ${num_workers} -cdh ${cdh_version} -N ${cluster_name}"
                python /var/lib/cloud/instance/scripts/deploy_on_oci.py -S -m ${cm_ip} -i ${fqdn_list} -d ${worker_disk_count} -w ${worker_shape} -n ${num_workers} -cdh ${cdh_version} -N ${cluster_name} 2>&1 1>> $LOG_FILE
        fi
else
        if [ $hdfs_ha = "true" ]; then
                log "---> python /var/lib/cloud/instance/scripts/deploy_on_oci.py -H -m ${cm_ip} -i ${fqdn_list} -d ${worker_disk_count} -w ${worker_shape} -n ${num_workers} -cdh ${cdh_version} -N ${cluster_name}"
                python /var/lib/cloud/instance/scripts/deploy_on_oci.py -H -m ${cm_ip} -i ${fqdn_list} -d ${worker_disk_count} -w ${worker_shape} -n ${num_workers} -cdh ${cdh_version} -N ${cluster_name} 2>&1 1>> $LOG_FILE
        else
                log "---> python /var/lib/cloud/instance/scripts/deploy_on_oci.py -m ${cm_ip} -i ${fqdn_list} -d ${worker_disk_count} -w ${worker_shape} -n ${num_workers} -cdh ${cdh_version} -N ${cluster_name}"
                python /var/lib/cloud/instance/scripts/deploy_on_oci.py -m ${cm_ip} -i ${fqdn_list} -d ${worker_disk_count} -w ${worker_shape} -n ${num_workers} -cdh ${cdh_version} -N ${cluster_name} 2>&1 1>> $LOG_FILE
        fi
fi
log "->DONE"
