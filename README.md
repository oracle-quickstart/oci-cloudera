# oci-quickstart-cloudera
This is a Terraform module that deploys [Cloudera Enterprise Data Hub](https://www.cloudera.com/products/enterprise-data-hub.html) on [Oracle Cloud Infrastructure (OCI)](https://cloud.oracle.com/en_US/cloud-infrastructure).  It is developed jointly by Oracle and Cloudera.

## Deployment Information
The following table shows Recommended and Minimum supported OCI shapes for each cluster role:

|             | Worker Nodes   | Bastion Instance | Utility and Master Instances |
|-------------|----------------|------------------|------------------------------|
| Recommended | BM.DenseIO2.52 | VM.Standard2.4   | VM.Standard2.16              |
| Minimum     | VM.Standard2.8 | VM.Standard2.1   | VM.Standard2.8               |

## Resource Manager Deployment
This quickstart leverages  [OCI Resource Manager](https://docs.cloud.oracle.com/iaas/Content/ResourceManager/Concepts/resourcemanager.htm) to make deployment quite easy.  Simply [download the latest .zip](https://github.com/oracle/oci-quickstart-cloudera/zipball/resource-manager) and follow the [Resource Manager instructions](https://docs.cloud.oracle.com/iaas/Content/ResourceManager/Tasks/usingconsole.htm) for how to build a stack.  Prior to building the Stack, you may want to modify some parts of the deployment detailed in the sections below and the scripts [README](https://github.com/oracle/oci-quickstart-cloudera/blob/master/scripts/README.md).

Alternatively you can also use a schema file to make setting deployment variables even easier.   In order to leverage this feature, the GitHub zipball must be re-packaged so that it's contents are top-level prior to creating the ORM Stack.  This is a straight forward process:
```
unzip oci-quickstart-cloudera*.zip
cd oci-quickstart-cloudera-<TAB_COMPLETE>
zip -r oci-quickstart-cloudera.zip *
```

Use the oci-quickstart-cloudera.zip file created in the last step to create the ORM Stack.  The schema file can even be customized for your use, enabling you to build a set of approved variables for deployment.

## Python Deployment using cm_client
The deployment script "deploy_on_oci.py" uses cm_client against Cloudera Manger API v31.  As such it does require some customization before execution.  Reference the header section in the script, it is highly encouraged you modify the following variables before deployment:

	admin_user_name
	admin_password

These variables are not passed too instance metadata for security purposes, as such they are only present in the CloudInit deployment script.  You can sanitize these after deployment by removing the contents of /var/lib/cloud/instance/scripts/.
In addition, advanced customization of the cluster deployment can be done by modification of the following functions:

	setup_mgmt_rcg
	update_cluster_rcg_configuration

This does require some knowledge of Python and Cloudera configuration - modify at your own risk.  These functions contain Cloudera specific tuning parameters as well as host mapping for roles.

## Kerberos Secure Cluster option

This automation supports using a local KDC deployed on the Cloudera Manager instance for secure cluster operation.  Please read the scripts [README](https://github.com/oracle/oci-quickstart-cloudera/blob/master/scripts/README.md) for information regarding how to set these parameters prior to deployment if desired.  This is now enabled by a True/False flag in ORM deployment, and is on by default.

Also - for cluster management, you will need to manually create at a minimum the HDFS Superuser Principal as [detailed here](https://www.cloudera.com/documentation/enterprise/latest/topics/cm_sg_using_cm_sec_config.html#create-hdfs-superuser) after deployment.
  
## High Availability

High Availability for HDFS services is also offered as part of the deployment process.  This can be toggled during the installation process by setting the value to "True".

## Metadata and MySQL

You can customize the default root password for MySQL by editing the source script [cms_mysql.sh](https://github.com/oracle/oci-quickstart-cloudera/blob/master/scripts/cms_mysql.sh#L188).  For the various Cloudera databases, random passwords are generated and used.  These are stored in a flat file on the Utility host for use at deployment time.

## Object Storage Integration
As of the 2.1.0 release, included with this template is a means to deploy clusters with configuration to allow use of OCI Object Storage using S3 Compatability.  In order to implement, an S3 Access and Secret key must be set up in the OCI Tenancy first.  This process is detailed [here](https://docs.cloud.oracle.com/iaas/Content/Identity/Tasks/managingcredentials.htm#Working2).  Once that is in place, modify the [deploy_on_oci.py](https://github.com/oci-quickstart/oci-cloudera/blob/master/scripts/deploy_on_oci.py#L133-L141) script, and set the following values:

        s3_compat_enable = 'False'
        s3a_secret_key = 'None'
        s3a_access_key = 'None'
        s3a_endpoint = 'None'

The first should be set to 'True', then replace 'None" with each of the required values.   This configuration will then be pushed as part of the cluster deployment.

## Architecture Diagram
Here is a diagram showing what is deployed using this template.   Note that resources are automatically distributed among Fault Domains in an Availability Domain to ensure fault tolerance.   Additional workers deployed will stripe between the 3 fault domains in sequence starting with the Fault Domain 1 and incrementing sequentially.

![Deployment Architecture Diagram](https://github.com/oracle/oci-quickstart-cloudera/blob/master/images/deployment_architecture.png)

