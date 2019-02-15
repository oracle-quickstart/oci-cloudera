#!/bin/bash

LOG_FILE="/var/log/cloudera-OCI-initialize.log"

# logs everything to the $LOG_FILE
log() {
  echo "$(date) [${EXECNAME}]: $*" >> "${LOG_FILE}"
}

EXECNAME="TUNING"

log "->START"
## Modify resolv.conf to ensure DNS lookups work
rm -f /etc/resolv.conf
echo "search public1.cdhvcn.oraclevcn.com public2.cdhvcn.oraclevcn.com public3.cdhvcn.oraclevcn.com private1.cdhvcn.oraclevcn.com private2.cdhvcn.oraclevcn.com private3.cdhvcn.oraclevcn.com bastion1.cdhvcn.oraclevcn.com bastion2.cdhvcn.oraclevcn.com bastion3.cdhvcn.oraclevcn.com" > /etc/resolv.conf
echo "nameserver 169.254.169.254" >> /etc/resolv.conf

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

## Set Limits
echo "hdfs  -       nofile  32768
hdfs  -       nproc   2048
hbase -       nofile  32768
hbase -       nproc   2048" >> /etc/security/limits.conf
ulimit -n 262144

systemctl stop firewalld
systemctl disable firewalld

## Enable root login via SSH key
cp /root/.ssh/authorized_keys /root/.ssh/authorized_keys.bak
cp /home/opc/.ssh/authorized_keys /root/.ssh/authorized_keys

## KERBEROS INSTALL
EXECNAME="KERBEROS"
log "-> INSTALL"

yum -y install krb5-server krb5-libs
KERBEROS_PASSWORD="SOMEPASSWORD"
OPC_USER_PASSWORD="somepassword"
kdc_server=$(hostname)
kdc_fqdn=`host $kdc_server | gawk '{print $1}'`
realm=`echo $kdc_fqdn |  cut -d '.' -f 3-5`
REALM=`echo $realm | tr [:lower:] [:upper:]`
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
 default_tkt_enctypes = des-cbc-md5 des-cbc-crc des3-cbc-sha1
 default_tgs_enctypes = des-cbc-md5 des-cbc-crc des3-cbc-sha1
 permitted_enctypes = des-cbc-md5 des-cbc-crc des3-cbc-sha1

[realms]
    ${REALM} = {
        kdc = ${kdc_fqdn}:88
        admin_server = ${kdc_fqdn}:749
        default_domain = ${realm}
    }

[domain_realm]
    .${realm} = ${REALM}
     ${realm} = ${REALM}

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
        supported_enctypes = arcfour-hmac:normal des3-hmac-sha1:normal des-cbc-crc:normal des:normal des:v4 des:norealm des:onlyrealm des:afs3
        default_principal_flags = +preauth
    }
EOF

rm -f /var/kerberos/krb5kdc/kadm5.acl
cat > /var/kerberos/krb5kdc/kadm5.acl << EOF
*/admin@${REALM}    *
EOF

kdb5_util create -r ${REALM} -s -P ${KERBEROS_PASSWORD}

echo -e "addprinc root/admin\n${KERBEROS_PASSWORD}\n${KERBEROS_PASSWORD}\naddprinc opc\n${OPC_USER_PASSWORD}\n${OPC_USER_PASSWORD}\nktadd -k /var/kerberos/krb5kdc/kadm5.keytab kadmin/admin\nktadd -k /var/kerberos/krb5kdc/kadm5.keytab kadmin/changepw\nexit\n" | kadmin.local -r ${REALM}
log "-> START"
systemctl start krb5kdc.service
systemctl start kadmin.service
systemctl enable krb5kdc.service
systemctl enable kadmin.service

## INSTALL CLOUDERA MANAGER
EXECNAME="Cloudera Manager & Pre-Reqs Install"
log "-> Installation"
rpm --import https://archive.cloudera.com/cdh6/6.1.0/redhat7/yum//RPM-GPG-KEY-cloudera
wget http://archive.cloudera.com/cm6/6.1.0/redhat7/yum/cloudera-manager.repo -O /etc/yum.repos.d/cloudera-manager.repo
yum install oracle-j2sdk* cloudera-manager-server java-1.8.0-openjdk.x86_64 python-pip -y
pip install psycopg2==2.7.5 --ignore-installed
yum install cloudera-manager-daemons -y

install_postgres(){
##
## POSTGRES SETUP BELOW
##

yum install postgreql-server -y

# manually set EXECNAME because this file is called from another script and it $0 is "bash"
EXECNAME="Postgresql Bootstrap"
CURRENT_VERSION_MARKER='OCI_1'
SLEEP_INTERVAL=5
}
##
## POSTGRES FUNCTIONS 
##

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

  #if pass in the third parameter, us it as the ROLE name
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

# Returns 0 if the given DB exists in the DB list file.
db_exists()
{
  grep -q -s -e "^$1$" "$DB_LIST_FILE"
}

create_random_password()
{
  perl -le 'print map { ("a".."z", "A".."Z", 0..9)[rand 62] } 1..10'
}

# Creates the SCM database, if it doesn't exist yet.
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
# Auto-generated by `basename $0`
#
# $NOW
#
# These are database settings for CM Manager
#
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
  # $1 is the MgmtServiceHandler.RoleNames Enum value
  # $2 is the database name.
  # hive has different db name and role name
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

  # Write the prop file header.
  if [[ ! -f $MGMT_DB_PROP_FILE ]]; then
    orig_umask=$(umask)
    umask 0077
    cat > "$MGMT_DB_PROP_FILE" << EOF
# Auto-generated by `basename $0`
#
# $NOW
#
# These are database credentials for databases
# created by "cloudera-scm-server-db" for
# Cloudera Manager Management Services,
# to be used during the installation wizard if
# the embedded database route is taken.
#
# The source of truth for these settings
# is the Cloudera Manager databases and
# changes made here will not be reflected
# there automatically.
#
EOF

    umask "$orig_umask"
    fail_or_continue $? "Error creating file $MGMT_DB_PROP_FILE"
  fi

  local PREFIX="com.cloudera.cmf.$role.db"

  # Append the role db properties to the mgmt db props file.
  cat >> "$MGMT_DB_PROP_FILE" <<EOF
$PREFIX.type=postgresql
$PREFIX.host=$DB_HOSTPORT
$PREFIX.name=$db
$PREFIX.user=$hive
$PREFIX.password=$pw
EOF
  fail_or_continue $? "Error updating file $MGMT_DB_PROP_FILE"

  # Update pg_hba.conf for the new database.
  echo "host    $db   $hive   0.0.0.0/0   md5" >> "$DATA_DIR"/pg_hba.conf

  echo "Created DB for role $role"
  echo "$db" >> "$DB_LIST_FILE"
}


# Creates a database for a specific role, if it doesn't exist yet.
create_mgmt_role_db()
{
  # $1 is the MgmtServiceHandler.RoleNames Enum value
  # $2 is the database name.
  local role=$1
  local db=$2
  if db_exists "$db"; then
    return 0
  fi

  echo "Creating DB $db for role $role"
  local pw
  pw=$(create_random_password)
  create_database "$db" "$pw"

  # Write the prop file header.
  if [[ ! -f $MGMT_DB_PROP_FILE ]]; then
    orig_umask=$(umask)
    umask 0077
    cat > "$MGMT_DB_PROP_FILE" << EOF
# Auto-generated by `basename $0`
#
# $NOW
#
# These are database credentials for databases
# created by "cloudera-scm-server-db" for
# Cloudera Manager Management Services,
# to be used during the installation wizard if
# the embedded database route is taken.
#
# The source of truth for these settings
# is the Cloudera Manager databases and
# changes made here will not be reflected
# there automatically.
#
EOF

    umask "$orig_umask"
    fail_or_continue $? "Error creating file $MGMT_DB_PROP_FILE"
  fi

  local PREFIX="com.cloudera.cmf.$role.db"

  # Append the role db properties to the mgmt db props file.
  cat >> "$MGMT_DB_PROP_FILE" <<EOF
$PREFIX.type=postgresql
$PREFIX.host=$DB_HOSTPORT
$PREFIX.name=$db
$PREFIX.user=$db
$PREFIX.password=$pw
EOF
  fail_or_continue $? "Error updating file $MGMT_DB_PROP_FILE"

  # Update pg_hba.conf for the new database.
  echo "host    $db   $db   0.0.0.0/0   md5" >> "$DATA_DIR"/pg_hba.conf

  log "-->Created DB for role $role"
  echo "$db" >> "$DB_LIST_FILE"
}

pg_hba_contains()
{
  grep -q -s -e "^$1$" "$DATA_DIR"/pg_hba.conf
}

# changes postgres config to allow remote connections. Idempotent.
configure_remote_connections()
{
  local FIRSTLINE="# block remote access for admin user"
  local SECONDLINE="host    all    postgres 0.0.0.0/0 reject"
  local THIRDLINE="# enable remote access for other users"
  local FOURTHLINE="host    sameuser all  0.0.0.0/0   md5"

  if pg_hba_contains "$FIRSTLINE"; then
    return 0
  fi
  # Update pg_hba.conf for the new database.
  echo "$FIRSTLINE" >> "$DATA_DIR"/pg_hba.conf
  echo "$SECONDLINE" >> "$DATA_DIR"/pg_hba.conf
  echo "$THIRDLINE" >> "$DATA_DIR"/pg_hba.conf
  echo "$FOURTHLINE" >> "$DATA_DIR"/pg_hba.conf

  log "-->Enabled remote connections"
}

# Get the amount of RAM on the system. Uses "free -b" to get the amount
# in bytes and parses the output to get total amount of memory available.
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

# We need to set a good value for postgresql shared_buffer parameter. Default
# is 32 MB which is too low. Postgresql recommends setting this to 1/4 of RAM
# if there is more than 1GB of RAM on the system (which is true for most systems
# today). This parameter also depends on the Linux maximum shared memory parameter
# (cat /proc/sys/kernel/shmmax)
# Few linux systems default the shmmax to 32 MB, below that level we should let
# postgresql default as is. Above this value, we will use 50% of the shmmax as
# the shared_buffer default value. Also maximum recommended value is 8GB, so
# we will ceil on 8 GB.
#
# shared_buffer is specified in kernel buffer cache block size, typically
# 1024 bytes (8192 bits). So the shared_buffer value * 8192 gives the memory
# in bits that will be used (actually table 17-2 of postgresql doc says that
# it should be 8192 + 208: http://www.postgresql.org/docs/9.1/static/kernel-resources.html)
#
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

  # On some systems we get value of shmmax that is out of range for integer
  # values that bash can process (see OPSAPS-11583). So we check for any
  # value that is greater than 99 GB (length > 11) and then floor shmmax value
  # to 16 GB (as 8GB is max shared buffer value, 50% of shmmax)
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
    # These lines will be fed to sed, add \\ to make them look like single line to sed
    echo "# This is needed to make Hive work with Postgresql 9.1 and above\\"
    echo "# See OPSAPS-11795\\"
    echo "standard_conforming_strings=off"
  fi
}

configure_postgresql_conf()
{
  local CONF_FILE="$1"
  local IS_UPGRADE="$2"
  # Re-configure the listen address and port, since the postgresql-server
  # package may be using the default postgres port and listen address.
  # Though typically the default configs don't specify a
  # port, we try to remove it anyway.

  # Listen on all IP addresses, as monitoring services may reside on
  # different machines on the LAN.
  sed -e '/^listen_addresses\s*=/d' -i "$CONF_FILE"

  # Bump up max connections to server and shared buffer space that connections
  # need. shared_buffers should be at least 2 * max_connections.
  sed -e '/^max_connections\s*=/d' -i "$CONF_FILE"
  sed -e '/^shared_buffers\s*=/d' -i "$CONF_FILE"
  sed -e '/^standard_conforming_strings\s*=/d' -i "$CONF_FILE"

  # Prepend to the file
  local TMPFILE
  TMPFILE=$(mktemp /tmp/XXXXXXXX)

  if [ "$IS_UPGRADE" -eq 0 ]; then
    cat > "$TMPFILE" << EOF
#########################################
# === Generated by cloudera-scm-server-db at $NOW
#########################################
EOF
  fi
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

##
## MAIN POSTGRES SETUP
##
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
#Add header to pg_hba.conf.
echo "# Accept connections from all hosts" >> $DATA_DIR/pg_hba.conf
#put this line to the top of the ident to allow all local access
sed -i '/host.*127.*ident/i \
  host    all         all         127.0.0.1/32          md5  \ ' $DATA_DIR/pg_hba.conf
#configure the postgresql server to start at boot
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
# restart to make sure all configuration take effects
log "-- Restarting Postgresql to refresh config --"
systemctl restart postgresql
wait_for_db_server_to_start
log "-- DONE --"
## DISK SETUP
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

## Look for all ISCSI devices in sequence, finish on first failure
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

## Check for x>0 devices
log "->Checking for disks..."
nvcount="0"
bvcount="0"
## Execute - will format all devices except sda for use as data disks in HDFS
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
## START CLOUDERA MANAGER
log "------- Starting Cloudera Manager -------"
chown -R cloudera-scm:cloudera-scm /etc/cloudera-scm-server
#chown -R cloudera-scm:cloudera-scm /opt/cloudera
#chown -R cloudera-scm:cloudera-scm /var/log/cloudera
systemctl start cloudera-scm-server

EXECNAME="END"
log "->DONE"
