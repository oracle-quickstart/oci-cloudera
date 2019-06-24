# oci-quickstart-cloudera
This is a Terraform module that deploys [Cloudera Enterprise Data Hub](https://www.cloudera.com/products/enterprise-data-hub.html) on [Oracle Cloud Infrastructure (OCI)](https://cloud.oracle.com/en_US/cloud-infrastructure).  It is developed jointly by Oracle and Cloudera.

## Alternate Versions
Future development will include support for EDH v5 clusters.  In the meantime, use the [1.0.0 release](https://github.com/oci-quickstart/oci-cloudera/releases/tag/1.0.0) for v5 deployments.

|             | Worker Nodes   | Bastion Instance | Utility and Master Instances |
|-------------|----------------|------------------|------------------------------|
| Recommended | BM.DenseIO2.52 | VM.Standard2.4   | VM.Standard2.16              |
| Minimum     | VM.Standard2.8 | VM.Standard2.1   | VM.Standard2.8               |

Host types can be customized in this template.   Also included with this template is an easy method to customize block volume quantity and size as pertains to HDFS capacity.   See [variables.tf](https://github.com/oracle/oci-quickstart-cloudera/blob/master/terraform/variables.tf#L48-L62)  for more information in-line.

## Prerequisites
First off you'll need to do some pre deploy setup.  That's all detailed [here](https://github.com/oracle/oci-quickstart-prerequisites).

### Clone the Module
Now, you'll want a local copy of this repo.  You can make that with the commands:

    git clone https://github.com/oracle/oci-quickstart-cloudera.git
    cd oci-quickstart-cloudera

## Python Deployment using cm_client
The deployment script "deploy_on_oci.py" uses cm_client against Cloudera Manger API v31.  As such it does require some customization before execution.  Reference the header section in the script, it is highly encouraged you modify the following variables before deployment:

	admin_user_name
	admin_password
	cluster_name

Also if you modify the compute.tf in any way to change hostname parameters, you will need to update these variables for pattern matching, otherwise cluster deployment will fail:

	worker_hosts_prefix = 'cdh-worker'
	namenode_host = 'cdh-master-1'
	secondary_namenode_host = 'cdh-master-2'
	cloudera_manager_host = 'cdh-utility-1'

In addition, further customization of the cluster deployment can be done by modification of the following functions:

	setup_mgmt_rcg
	update_cluster_rcg_configuration

This does require some knowledge of Python and Cloudera - modify at your own risk.  These functions contain Cloudera specific tuning parameters as well as host mapping for roles.

## Kerberos Secure Cluster option

This automation supports using a local KDC deployed on the Cloudera Manager instance for secure cluster operation.  Please read the scripts [README](https://github.com/oracle/oci-quickstart-cloudera/blob/master/scripts/README.md) for information regarding how to set these parameters prior to deployment.

Also - for cluster management, you will need to manually create at a minimum the HDFS Superuser Principal as [detailed here](https://www.cloudera.com/documentation/enterprise/latest/topics/cm_sg_using_cm_sec_config.html#create-hdfs-superuser) after deployment.

Enabling Kerberos is managed using a terraform metadata tag "deployment_type" which is set in [variables.tf](https://github.com/oracle/oci-quickstart-cloudera/blob/master/terraform/variables.tf#L32).   Setting this value to "secure" will enable cluster security as part of the setup process.  Changing this to "simple" will deploy an unsecured cluster.

## High Availability

High Availability is also offered as part of the deployment process.  When secure cluster operation is chosen this is enabled by default.  It can be disabled by either changing the deployment_type to "simple", or modifying the [deploy_on_oci.py](https://github.com/oracle/oci-quickstart-cloudera/blob/master/scripts/deploy_on_oci.py#L60) script and changing the value for "hdfs_ha" to False.

## Metadata and MySQL

You can customize the default root password for MySQL by editing the source script [cms_mysql.sh](https://github.com/oracle/oci-quickstart-cloudera/blob/master/scripts/cms_mysql.sh#L188).  For the various Cloudera databases, random passwords are generated and used.  These are stored in a flat file on the Utility host for use at deployment time.

## Object Storage Integration
As of the 2.1.0 release, included with this template is a means to deploy clusters with configuration to allow use of OCI Object Storage using S3 Compatability.  In order to implement, an S3 Access and Secret key must be set up in the OCI Tenancy first.  This process is detailed [here](https://docs.cloud.oracle.com/iaas/Content/Identity/Tasks/managingcredentials.htm#Working2).  Once that is in place, modify the [deploy_on_oci.py](https://github.com/oracle/oci-quickstart-cloudera/blob/master/scripts/deploy_on_oci.py#L101-L108) script, and set the following values:

	s3_compat_enable = 'False'
	s3a_secret_key = 'None'
	s3a_access_key = 'None'
	s3a_endpoint = 'None'	

The first should be set to 'True', then replace 'None" with each of the required values.   This configuration will then be pushed as part of the cluster deployment.

## Deployment Syntax
Deployment of the module is straight forward using the following Terraform commands

	terraform init
	terraform plan
	terraform apply

This will create all the required elements in a compartment in the target OCI tenancy.  This includes VCN and Security List parameters.  Security audit of these in the [network module](https://github.com/oracle/oci-quickstart-cloudera/blob/master/terraform/modules/network/main.tf) is suggested.

## Destroy the Deployment

When you no longer need the deployment, you can run this command to destroy it:

	terraform destroy

## Deployment Architecture

Here is a diagram showing what is deployed using this template.   Note that resources are automatically distributed among Fault Domains in an Availability Domain to ensure fault tolerance.   Additional workers deployed will stripe between the 3 fault domains in sequence starting with the Fault Domain 1 and incrementing sequentially.

![Deployment Architecture Diagram](https://github.com/oracle/oci-quickstart-cloudera/blob/master/images/deployment_architecture.png)

