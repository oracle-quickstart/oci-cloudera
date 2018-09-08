#!/bin/bash
## Java install
cd /home/opc/java/
for java_rpm in `ls *.rpm`; do
        if [ -z $java_rpm ]; then
                sleep .001
        else
                for host in `cat /home/opc/host_list`; do
                        scp -o BatchMode=yes -o StrictHostKeyChecking=no -i /home/opc/.ssh/id_rsa ${java_rpm} root@$host:/home/opc/
                        ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i /home/opc/.ssh/id_rsa root@$host "rpm -Uvh /home/opc/${java_rpm}"
                done;
        fi
done;
