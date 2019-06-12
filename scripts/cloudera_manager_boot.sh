#!/bin/bash
LOG_FILE="/var/log/cloudera-OCI-initialize.log"
log() { 
	echo "$(date) [${EXECNAME}]: $*" >> "${LOG_FILE}" 
}
EXECNAME="Metadata Extraction"
log "->Deployment Script Decode"
curl -L http://169.254.169.254/opc/v1/instance/metadata/deploy_on_oci | base64 -d >> deploy_on_oci.py.gz
log "-->Extract"
gunzip deploy_on_oci.py.gz >> $LOG_FILE
log "->CMS Setup Script Decode"
curl -L http://169.254.169.254/opc/v1/instance/metadata/cm_install | base64 -d >> cms_mysql.sh.gz
log"-->Extract"
gunzip cms_mysql.sh.gz
chmod +x cms_mysql.sh
EXECNAME="CMS Setup"
log "->Execute"
./cms_mysql.sh
