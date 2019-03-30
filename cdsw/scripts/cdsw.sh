#!/bin/bash
#
## Install JQ
yum install jq -y
## Cluster Specific Variables
CLUSTER="TestCluster"
cdhlogin="cdhadmin"
cdhpassword="somepassword"
CLOUDERA_MANAGER="cdh-utility-1"
cm_ip=`nslookup cdh-utility-1 | grep Address | sed 1d | gawk '{print $2}'`
cm1=`echo $cm_ip | cut -d '.' -f 1`
cm2=`echo $cm_ip | cut -d '.' -f 2`
cm3=`echo $cm_ip | cut -d '.' -f 3`
cm4= `echo $cm_ip | cut -d '.' -f 4`
DOMAIN="cdsw.${cm1}.${cm2}.${cm3}.${cm4}.nip.io"
#NVPATH="\/some\/path\/here"
## Functions


# Download JAR file - version pathing is hard coded here
cdsw_download () {
	wget https://archive.cloudera.com/cdsw1/1.4.2/csd/CLOUDERA_DATA_SCIENCE_WORKBENCH-CDH5-1.4.2.jar -O /opt/cloudera/csd/CLOUDERA_DATA_SCIENCE_WORKBENCH-CDH5-1.4.2.jar
}

spark2_download () {
	wget https://archive.cloudera.com/spark2/csd/SPARK2_ON_YARN-2.3.0.cloudera3.jar -O /opt/cloudera/csd/SPARK2_ON_YARN-2.3.0.cloudera3.jar
}

# Add Parcel REPOs to Cloudera Manager
cdsw_parcel_add () {
	echo -e "Adding CDSW Parcel REPO."
	curl -s -u ${cdhlogin}:${cdhpassword} http://${CLOUDERA_MANAGER}:7180/api/v19/cm/config -X PUT -H "Content-Type: application/json" --data '{ "items": [ { "name": "REMOTE_PARCEL_REPO_URLS", "value": "https://archive.cloudera.com/cdsw1/1.4.2/parcels/" } ]}'
}

spark2_parcel_add () { 
	echo -e "Adding Spark2 Parcel REPO."
        curl -s -u ${cdhlogin}:${cdhpassword} http://${CLOUDERA_MANAGER}:7180/api/v19/cm/config -X PUT -H "Content-Type: application/json" --data '{ "items": [ { "name": "REMOTE_PARCEL_REPO_URLS", "value": "http://archive.cloudera.com/spark2/parcels/2.3.0.cloudera3/" } ]}'
}

## Cluster Commands
restart_cluster () {
	curl -s -u ${cdhlogin}:${cdhpassword} http://${CLOUDERA_MANAGER}:7180/api/v19/clusters/${CLUSTER}/commands/restart -X POST -H "Content-Type: application/json" -d '{ }' 2&>1 2>/dev/null
}

# In case other operations are needed
cluster_command () {
	curl -s -u ${cdhlogin}:${cdhpassword} http://${CLOUDERA_MANAGER}:7180/api/v19/clusters/${CLUSTER}/commands/${COMMAND} -X POST -H "Content-Type: application/json" -d '{ }' 2&>1 2>/dev/null
}

# Check cluster status
check_cluster () {
        for SERVICE in `curl -s -u ${cdhlogin}:${cdhpassword} -X GET http://${CLOUDERA_MANAGER}:7180/api/v19/clusters/${CLUSTER}/services/ | jq '.items[].name' | cut -d '"' -f 2`; do
		echo -e "${SERVICE} [|]"
		SERVICE_STATUS="0"
		bitflip="1"
		while [ $SERVICE_STATUS != "STARTED" ]; do 
                	SERVICE_STATUS=`curl -s -u ${cdhlogin}:${cdhpassword} -X GET http://${CLOUDERA_MANAGER}:7180/api/v19/clusters/${CLUSTER}/services/ | jq --arg SERVICE "$SERVICE" '.items[] | select(.name == $SERVICE) | .serviceState' | cut -d '"' -f2`
			if [ $SERVICE_STATUS = "STARTED" ]; then 
				echo -ne "\e[1A"
				echo -e "${SERVICE} [OK]"
				continue
			elif [ $bitflip = "0" ]; then
				echo -ne "\e[1A"
				echo -e "${SERVICE} [/]"
				bitflip="1"
				sleep 1
			elif [ $bitflip = "1" ]; then 
                                echo -ne "\e[1A"
                                echo -e "${SERVICE} [-]"
                                bitflip="2"
                                sleep 1
			elif [ $bitflip = "2" ]; then 
                                echo -ne "\e[1A"
                                echo -e "${SERVICE} [\\]"
                                bitflip="3"
                                sleep 1
			else
                                echo -ne "\e[1A"
                                echo -e "${SERVICE} [|]"
				bitflip="0"
                                sleep 1
			fi
        	done;
	done;
}


## Parcel Commands
# Check Parcel Status for $value
check_parcel () {
echo -e "$PRODUCT PARCEL STATUS: "
while [ "$result" != "$value" ]; do
	result=`curl -s -u ${cdhlogin}:${cdhpassword} -X GET http://${CLOUDERA_MANAGER}:7180/api/v19/clusters/${CLUSTER}/parcels/ | jq --arg PRODUCT "$PRODUCT" '.items[] | select(.product == $PRODUCT) | .stage' | cut -d '"' -f2`
	if [ -z "$result" ]; then 
		continue
	fi
	case $result in 
		${value})
                echo -ne "\e[1A"
                echo -e "$PRODUCT PARCEL STATUS: $result" 
		;;

		ACTIVATED)
                echo -ne "\e[1A"
                echo -e "$PRODUCT PARCEL STATUS: $result"
		result="$value" 		
		;;
		
		*)
                echo -ne "\e[1A"
                echo -e "$PRODUCT PARCEL STATUS: $result"
		sleep 5 
		;;
	esac
done;
}

# Get PRODUCT_VERSION for PRODUCT from parcel info
parcel_version () {
	PRODUCT_VERSION=`curl -s -u ${cdhlogin}:${cdhpassword} http://${CLOUDERA_MANAGER}:7180/api/v19/clusters/${CLUSTER}/parcels -X GET | jq --arg PRODUCT "$PRODUCT" '.items[] | select(.product == $PRODUCT) | .version' | cut -d '"' -f2`
}

# Perform Parcel COMMAND against specified PRODUCT and PRODUCT_VERSION
parcel_action () {
	curl -s -u ${cdhlogin}:${cdhpassword} http://${CLOUDERA_MANAGER}:7180/api/v19/clusters/${CLUSTER}/parcels/products/${PRODUCT}/versions/${PRODUCT_VERSION}/commands/${COMMAND} -X POST -H "Content-Type: application/json" -d '{ }' 2&>1 2>/dev/null
}

## Pre-requisites
begin_setup () {
	# Download CDSW jar
	#echo -e "Downloading CDSW JAR."
	#cdsw_download

	# Download SPARK2 jar
	spark2_download

	# Restart Cloudera Manager
	echo -e "Restarting Cloudera Manager."
	ssh -i /home/opc/.ssh/id_rsa ${CLOUDERA_MANAGER} 'service cloudera-scm-server restart'

	## Sanity Check
	# Check that SCM is running - the SCM startup takes some time
	echo -n "Waiting for SCM server to be available [*"
	scm_chk="1"
	while [ "$scm_chk" != "0" ]; do
	        scm_lsn=`ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i /home/opc/.ssh/id_rsa ${CLOUDERA_MANAGER} 'netstat -tlpn | grep 7180'`
	       	if [ $? = "0" ]; then
	                echo -n "*] - [OK]"
	                echo -e "\n"
         	       scm_chk="0"
	        else
        	        echo -n "*"
	                sleep 5
	        fi
	done;
	#cdsw_parcel_add
	spark2_parcel_add
}

## Deply PRODUCT
deploy () { 
for COMMAND in "startDownload" "startDistribution" "activate"; do
        case $COMMAND in
                startDownload)
                value="DOWNLOADED"
		echo -e "$PRODUCT DOWNLOAD ISSUED"
                ;;

                startDistribution)
                value="DISTRIBUTED"
		echo -e "$PRODUCT DISTRIBUTION ISSUED"
                ;;

                activate)
                value="ACTIVATED"
		echo -e "$PRODUCT ACTIVATION ISSUED"
                ;;
        esac
	parcel_action
	sleep 5
	check_parcel
done;
}


##
## MAIN
##

echo -e "Starting Cloudera Data Science Workbench Installation."
begin_setup

# Cluster Restart to reload Cloudera Management Service
echo -e "Restarting Cluster."
restart_cluster
echo -e "Waiting 30 seconds."
sleep 30 
echo -e "Checking Cluster."
check_cluster

# Main Deployment
#for PRODUCT in "SPARK2" "CDSW"; do
for PRODUCT in "SPARK2"; do 
	parcel_version
	deploy
done;

## CDSW Repo
#echo -e "Downloading CDSW Repo."
#wget https://archive.cloudera.com/cdsw1/1.4.0/redhat7/yum/cloudera-cdsw.repo -O /etc/yum.repos.d/cloudera-cdsw.repo
#rpm --import https://archive.cloudera.com/cdsw1/1.4.0/redhat7/yum/RPM-GPG-KEY-cloudera

## CDSW RPM
echo -e "Downloading CDSW RPM."
#wget https://archive.cloudera.com/cdsw1/1.4.0/redhat7/yum/RPMS/x86_64/cloudera-data-science-workbench-1.4.0.431664-1.el7.centos.x86_64.rpm
wget https://archive.cloudera.com/cdsw1/1.4.2/redhat7/yum/RPMS/x86_64/cloudera-data-science-workbench-1.4.2.624065-1.el7.centos.x86_64.rpm

## Pre-Requisites
echo -e "Installing Pre-requisites."
yum install libtool-ltdl nfs-utils nmap-ncat ntp socat iptables-services -y
service iptables start
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X
echo -e "Installing CDSW."
#yum install cloudera-data-science-workbench -y
#rpm -Uvh cloudera-data-science-workbench-1.4.0.431664-1.el7.centos.x86_64.rpm
rpm -Uvh cloudera-data-science-workbench-1.4.2.624065-1.el7.centos.x86_64.rpm

#Edit /etc/cdsw/config/cdsw.conf
cdsw_conf="/etc/cdsw/config/cdsw.conf"
sed -i 's/cdsw.company.com/'"${DOMAIN}"'/g' ${cdsw_conf}
#MASTER_IP=`nslookup cdh-utility-1 | grep Address | sed 1d | gawk '{print $2}'`
MASTER_IP=`host cdh-utility-1 | head -n 1 | gawk '{print $4}'`
sed -i 's/MASTER_IP=""/MASTER_IP="'"${MASTER_IP}"'"/g' ${cdsw_conf}
sed -i 's/DOCKER_BLOCK_DEVICES=""/DOCKER_BLOCK_DEVICES="\/dev\/sdb"/g' ${cdsw_conf}
#sed -i 's/false/true/g' ${cdsw_conf}
#sed -i 's/NVIDIA_LIBRARY_PATH=/NVIDIA_LIBRARY_PATH="'"${NVPATH}"'"/g' $cdsw_conf

cdsw init

for worker in `cat /home/opc/hosts | grep worker | gawk '{print $2}'`; do 
	scp -i /home/opc/.ssh/id_rsa -oBatchMode=yes -oStrictHostKeyChecking=no ~/cloudera-data-science-workbench-1.4.2.624065-1.el7.centos.x86_64.rpm root@${worker}:/home/opc/
	ssh -i /home/opc/.ssh/id_rsa -oBatchMode=yes -oStrictHostKeyChecking=no root@${worker} 'yum install libtool-ltdl nfs-utils nmap-ncat ntp socat -y'
	ssh -i /home/opc/.ssh/id_rsa -oBatchMode=yes -oStrictHostKeyChecking=no root@${worker} 'rpm -Uvh /home/opc/cloudera-data-science-workbench-1.4.2.624065-1.el7.centos.x86_64.rpm'
	#ssh -i /home/opc/.ssh/id_rsa -o BatchMode=yes -o StrictHostKeyChecking=no ${worker} 'wget https://archive.cloudera.com/cdsw1/1.4.0/redhat7/yum/cloudera-cdsw.repo -O /etc/yum.repos.d/cloudera-cdsw.repo'
	#ssh -i /home/opc/.ssh/id_rsa -o BatchMode=yes -o StrictHostKeyChecking=no ${worker} 'rpm --import https://archive.cloudera.com/cdsw1/1.4.0/redhat7/yum/RPM-GPG-KEY-cloudera'
	#ssh -i /home/opc/.ssh/id_rsa -o BatchMode=yes -o StrictHostKeyChecking=no ${worker} 'yum install cloudera-data-science-workbench -y'
	scp -i /home/opc/.ssh/id_rsa -o BatchMode=yes -o StrictHostKeyChecking=no /etc/cdsw/config/cdsw.conf ${worker}:/etc/cdsw/config/cdsw.conf
	ssh -i /home/opc/.ssh/id_rsa -o BatchMode=yes -o StrictHostKeyChecking=no ${worker} 'cdsw join'
done;

watch cdsw status




