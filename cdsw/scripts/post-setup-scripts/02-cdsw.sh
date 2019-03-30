#!/bin/bash
CDSW_HOST="cdh-utility-1"
chmod +x /home/opc/cdsw.sh
scp -o BatchMode=yes -o StrictHostKeyChecking=no -i /home/opc/.ssh/id_rsa /home/opc/cdsw.sh root@${CDSW_HOST}:/home/opc/
scp -o BatchMode=yes -o StrictHostKeyChecking=no -i /home/opc/.ssh/id_rsa /home/opc/.ssh/id_rsa root@${CDSW_HOST}:/home/opc/.ssh/
ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i /home/opc/.ssh/id_rsa root@${CDSW_HOST} '/home/opc/cdsw.sh'
