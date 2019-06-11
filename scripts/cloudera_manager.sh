#!/bin/bash
curl -L http://169.254.169.254/opc/v1/instance/metadata/deploy_on_oci | base64 -d >> deploy_on_oci.py.gz
gunzip deploy_on_oci.py.gz
curl -L http://169.254.169.254/opc/v1/instance/metadata/cm_install | base64 -d >> cm_boot_mysql.sh.gz
gunzip cm_boot_mysql.sh.gz
chmod +x cm_boot_mysql.sh
sh cm_boot_mysql.sh
