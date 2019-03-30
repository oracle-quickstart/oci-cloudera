#!/bin/bash
yum install bind bind-utils -y
cp /home/opc/named.conf /etc/named.conf
cp /home/opc/*.zone /etc/named/
echo 'OPTIONS="-4"' >> /etc/sysconfig/named
systemctl restart named
systemctl enable named
