# scripts
All scripts in this location are referenced for deployment automation

* boot.sh is invoked by cloudinit on each instance creation via Terraform.  It contains steps which perform inital bootstrapping of the instance prior to provisioning.
* cm_boot_mysql.sh is invoked by cloudinit on the Utility node to stand up Cloudera Manager and Pre-requisites using MySQL for Metadata.
* cm_boot_postgres.sh can be used instead of cm_boot_mysql.sh if you want to use Postgres for Cloudera Manager and Cluster Metadata.
* deploy_on_oci.py is the primary Python script invoked to deploy Cloudera EDH v6 using cm_client python libraries

# CloudInit boot scripts

With the introduction of local KDC for secure cluster, this requires some setup at the instance level as part of the bootstrapping process.  To facilitate local KDC, this automation is inserted into the Cloudera Manager CloudInit boot script.   There is also a dependency for krb5.conf on the cluster hosts, prior to enabling Cloudera Manager management of these Kerberos client files.  KDC setup depends on a few parameters which can be modified prior to deployment:

* boot.sh
  * kdc_server - This is the hostname where KDC is deployed (defaults to Cloudera Manager host)
  * realm - This is set to hadoop.com by default.
  * REALM - This is set to HADOOP.COM by default.
* cm_boot_mysql.sh
  * KERBEROS_PASSWORD - This is used for the root/admin account.
  * SCM_USER_PASSWORD - By default the cloudera-scm user is given admin control of the KDC.  This is required for Cloudera Manager to setup and manage principals, and the password here is used by that account.
  * kdc_server - Defaults to local hostname.
  * realm - This is set to hadoop.com by default.  
  * REALM - This is set to HADOOP.COM by default.
* cm_boot_postgres.sh - Same items as cm_boot_mysql.sh
* deploy_on_oci.py
  * realm - This is HADOOP.COM by default.
  * kdc_admin - Set to cloudera-scm@HADOOP.COM by default.
  * kdc_password - This should match what is set in the CM boot script for SCM_USER_PASSWORD.

It is highly suggested you modify at a minimum the default passwords prior to deployment.

## CAUTION WHEN MODIFYING BOOT SCRIPTS
Because boot.sh and cm_boot_mysql.sh/cm_boot_postgres.sh  are invoked as part of user_data in Terraform, if you modify these files and re-run a deployment, default behavior is existing instances will be destroyed and re-deployed because of this change.   
