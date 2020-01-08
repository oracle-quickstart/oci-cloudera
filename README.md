# oci-quickstart-cloudera
This is a Terraform module that deploys [Cloudera Enterprise Data Hub](https://www.cloudera.com/products/enterprise-data-hub.html) on [Oracle Cloud Infrastructure (OCI)](https://cloud.oracle.com/en_US/cloud-infrastructure).  It is developed jointly by Oracle and Cloudera.  This module also supports installation of [Cloudera Data Platform](https://www.cloudera.com/products/cloudera-data-platform.html).

## Deployment Information
The following table shows Recommended and Minimum supported OCI shapes for each cluster role:

|             | Worker Nodes   | Bastion Instance | Utility and Master Instances |
|-------------|----------------|------------------|------------------------------|
| Recommended | BM.DenseIO2.52 | VM.Standard2.4   | VM.Standard2.16              |
| Minimum     | VM.Standard2.8 | VM.Standard2.1   | VM.Standard2.8               |

## Resource Manager Deployment
This quickstart leverages  [OCI Resource Manager](https://docs.cloud.oracle.com/iaas/Content/ResourceManager/Concepts/resourcemanager.htm) to make deployment quite easy.  Simply [download the latest .zip](https://github.com/oracle-quickstart/oci-cloudera/archive/master.zip) and follow the [Resource Manager instructions](https://docs.cloud.oracle.com/iaas/Content/ResourceManager/Tasks/usingconsole.htm) for how to build a stack.  Prior to building the Stack, you may want to modify some parts of the deployment detailed in the sections below.

It is highly suggested you use the included schema file to make deployment even easier.   In order to leverage this feature, the GitHub zipball must be re-packaged so that it's contents are top-level prior to creating the ORM Stack.  This is a straight forward process:
```
unzip oci-cloudera-master.zip
cd oci-cloudera-master
zip -r oci-cloudera-orm.zip *
```

Use the oci-cloudera-orm.zip file created in the last step to create the ORM Stack.  The schema file can even be customized for your use, enabling you to build a set of approved variables for deployment.

This template now leverages Terraform v0.12, and has support to target existing VCN/Subnets for cluster deployment.   To engage this functionality, just use the Schema menu system to select an existing VCN target, then select appropriate Subnets for each cluster host type.

Note that if you deploy Cloudera Manager to a private subnet, you will require a VPN or SSH Tunnel through an edge node to access cluster management.

## Python Deployment using cm_client
The deployment script "deploy_on_oci.py" uses cm_client against Cloudera Manager API v31.  This script can be customized before execution.  Reference the header section in the script, it is highly encouraged you modify the following variables before deployment:

	admin_user_name
	admin_password

These variables are not passed to instance metadata for security purposes, as such they are only present in the CloudInit python deployment script.  You can sanitize these after deployment by removing the contents of /var/lib/cloud/instance/scripts/.
In addition, advanced customization of the cluster deployment can be done by modification of the following functions:

	setup_mgmt_rcg
	update_cluster_rcg_configuration

This does require some knowledge of Python and Cloudera configuration - modify at your own risk.  These functions contain Cloudera specific tuning parameters as well as host mapping for roles.

## Kerberos Secure Cluster option

This automation supports using a local KDC deployed on the Cloudera Manager instance for secure cluster operation.  Please read the scripts [README](https://github.com/oracle-quickstart/oci-cloudera/blob/master/scripts/README.md) for information regarding how to set these parameters prior to deployment if desired.  This can be toggled during ORM stack setup using the schema.

Also - for cluster management using Kerberos, you will need to manually create at a minimum the HDFS Superuser Principal as [detailed here](https://www.cloudera.com/documentation/enterprise/latest/topics/cm_sg_using_cm_sec_config.html#create-hdfs-superuser) after deployment.
  
## High Availability

High Availability for HDFS services is also offered as part of the deployment process.  This can be toggled during ORM stack setup using the Schema.

## Metadata and MySQL

You can customize the default root password for MySQL by editing the source script [cms_mysql.sh](https://github.com/oracle-quickstart/oci-cloudera/blob/master/scripts/cms_mysql.sh#L188).  For the various Cloudera databases, random passwords are generated and used.  These are stored in a flat file on the Utility host for use at deployment time.  This file should be removed after you notate/change the pre-generated passwords, it is located here on the Utility node:  /etc/mysql/mysql.pw

## Object Storage Integration

Object Storage can also be leveraged by setting S3 compatability paramaters in the Python deployment script.   Details can be found in the [header section](https://github.com/oracle-quickstart/oci-cloudera/blob/8af97b91fb50cd77262c97580454137c2955dd4e/scripts/deploy_on_oci.py#L79-L86).  You will need to setup the appropriate S3 compatability pre-requisites as [detailed here](https://docs.cloud.oracle.com/iaas/Content/Identity/Tasks/managingcredentials.htm#Working2) for this to work.

## Architecture Diagram
Here is a diagram showing what is typically deployed using this template.   Note that resources are automatically distributed among Fault Domains in an Availability Domain to ensure fault tolerance.   Additional workers deployed will stripe between the 3 fault domains in sequence starting with the Fault Domain 1 and incrementing sequentially.

![Deployment Architecture Diagram](https://github.com/oracle/oci-quickstart-cloudera/blob/master/images/deployment_architecture.png)

