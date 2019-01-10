#!/bin/bash
cdh_version="6.1.0"
rpm --import https://archive.cloudera.com/cdh6/${cdh_version}/redhat7/yum//RPM-GPG-KEY-cloudera
wget http://archive.cloudera.com/cm6/${cdh_version}/redhat7/yum/cloudera-manager.repo -O /etc/yum.repos.d/cloudera-manager.repo
yum install -y oracle-j2sdk* cloudera-manager-daemons cloudera-manager-server
