# oci-quickstart-cloudera
This is a Terraform module that deploys [Cloudera Enterprise Data Hub](https://www.cloudera.com/products/enterprise-data-hub.html) on [Oracle Cloud Infrastructure (OCI)](https://cloud.oracle.com/en_US/cloud-infrastructure).  It is developed jointly by Oracle and Cloudera.

## Alternate Versions
Future development will include support for EDH v5 clusters.  In the meantime, use the [1.0.0 release](https://github.com/oci-quickstart/oci-cloudera/releases/tag/1.0.0) for v5 deployments.

|             | Worker Nodes   | Bastion Instance | Utility and Master Instances |
|-------------|----------------|------------------|------------------------------|
| Recommended | BM.DenseIO2.52 | VM.Standard2.4   | VM.Standard2.16              |
| Minimum     | VM.Standard2.8 | VM.Standard2.1   | VM.Standard2.8               |

Host types can be customized in this template.   Also included with this template is an easy method to customize block volume quantity and size as pertains to HDFS capacity.   See [variables.tf](https://github.com/oracle/oci-quickstart-cloudera/blob/master/terraform/variables.tf#L48-L62)  for more information in-line.

## Resource Manager Deployment
Using [OCI Resource Manager](https://docs.cloud.oracle.com/iaas/Content/ResourceManager/Concepts/resourcemanager.htm) makes deployment quite easy.  Simply [download the .zip](https://github.com/oracle/oci-quickstart-cloudear/zipball/resource-manager) and follow the [Resource Manager instructions](https://docs.cloud.oracle.com/iaas/Content/ResourceManager/Tasks/usingconsole.htm) for how to build a stack.  Prior to building the Stack, you may want to modify some parts of the deployment detailed in the sections below.

## Python Deployment using cm_client
The deployment script "deploy_on_oci.py" uses cm_client against Cloudera Manger API v31.  As such it does require some customization before execution.  Reference the header section in the script, it is highly encouraged you modify the following variables before deployment:

	admin_user_name
	admin_password

In addition, advanced customization of the cluster deployment can be done by modification of the following functions:

	setup_mgmt_rcg
	update_cluster_rcg_configuration

This does require some knowledge of Python and Cloudera configuration - modify at your own risk.  These functions contain Cloudera specific tuning parameters as well as host mapping for roles.

## Kerberos Secure Cluster option

This automation supports using a local KDC deployed on the Cloudera Manager instance for secure cluster operation.  Please read the scripts [README](https://github.com/oracle/oci-quickstart-cloudera/blob/master/scripts/README.md) for information regarding how to set these parameters prior to deployment.

Also - for cluster management, you will need to manually create at a minimum the HDFS Superuser Principal as [detailed here](https://www.cloudera.com/documentation/enterprise/latest/topics/cm_sg_using_cm_sec_config.html#create-hdfs-superuser) after deployment.

Enabling Kerberos is managed using a terraform metadata tag "deployment_type".   Setting this value to "secure" will enable cluster security as part of the setup process.  Changing this to "simple" will deploy an unsecured cluster.  By default this value is set to "simple" for speed of deployment and ease of use for those not familiar with secure cluster operation.

## High Availability

High Availability is also offered as part of the deployment process.  When secure cluster operation is chosen this is enabled by default.  It can be disabled by either changing the deployment_type to "simple", or modifying the [deploy_on_oci.py](https://github.com/oracle/oci-quickstart-cloudera/blob/master/scripts/deploy_on_oci.py#L60) script and changing the value for "hdfs_ha".

## Metadata and MySQL

You can customize the default root password for MySQL by editing the source script [cms_mysql.sh](https://github.com/oracle/oci-quickstart-cloudera/blob/master/scripts/cms_mysql.sh#L188).  For the various Cloudera databases, random passwords are generated and used.  These are stored in a flat file on the Utility host for use at deployment time.

## Object Storage Integration
As of the 2.1.0 release, included with this template is a means to deploy clusters with configuration to allow use of OCI Object Storage using S3 Compatability.  In order to implement, an S3 Access and Secret key must be set up in the OCI Tenancy first.  This process is detailed [here](https://docs.cloud.oracle.com/iaas/Content/Identity/Tasks/managingcredentials.htm#Working2).  Once that is in place, modify the [deploy_on_oci.py](https://github.com/oracle/oci-quickstart-cloudera/blob/master/scripts/deploy_on_oci.py#L101-L108) script, and set the following values:

	s3_compat_enable = 'False'
	s3a_secret_key = 'None'
	s3a_access_key = 'None'
	s3a_endpoint = 'None'	

The first should be set to 'True', then replace 'None" with each of the required values.   This configuration will then be pushed as part of the cluster deployment.

## Resource Manager Variables
Step 2 for setting up a stack is Configure Variables.   By default all variables are filled in, with the exception of the SSH Public and Private keypair used for host access.   If you don't have a keypair for use with this deployment, generating one on Linux/Mac is simply:

	ssh-keygen -t rsa

Follow the prompts to generate the key, do not associate a password with it.    Copy the contents of each file and paste into the appropriate variable fields as shown here:

![Resource Manager Variables](https://github.com/oracle/oci-quickstart-cloudera/blob/resource-manager/images/RM_variables.png)

This list also can be modified to suit your specific deployment requirements.   You should review the settings for the following and ensure you have the capacity in your Tenancy prior to deployment:

	worker_instance_shape
	worker_node_count
	block_volumes_per_worker
	utility_instance_shape
	master_instance_shape
	bastion_instance_shape

Note that it is not suggested to modify the data_blocksize_in_gbs to lower than the default value of 700GB.   This is because 700GB is the minimum value to achieve maximum throughput per block volume.  Lowering this has a negative impact on HDFS performance.  If you need more HDFS capacity, best practice is to increase the block_volumes_per_worker which adds more DFS volumes for capacity and aggregate throughput.  For even higher density, the data_blocksize_in_gbs can be increased in tandem.   

When using DenseIO shapes, it's also possible to set the block_volumes_per_worker to "0" to leverage only local NVME disk for HDFS.   In the case that you have both local NVME and block, data tiering will automatically be enabled as part of the deployment process.

## Resource Manager Stack Steps
After building the stack, it only takes 2 actions to deploy:

	Terraform Actions -> Plan
	Terraform Actions -> Apply

This will create all the required elements in a compartment in the target OCI tenancy.  This includes VCN and Security List parameters.  Security audit of these in the [network module](https://github.com/oracle/oci-quickstart-cloudera/blob/master/terraform/modules/network/main.tf) is suggested.

The output of the Apply command will contain a URL to access Cloudera Manager.   This is the public IP of the Utility Host, which runs the deployment.   

## Monitoring Cluster Build
Because all tasks are done in CloudInit, there are two ways to monitor the deployment.   Firstly you can login go the Cloudera Manager URL once it is up and running a few minutes after the Apply command finishes.  Alternatively you can SSH into the Utility node, and monitor the log file "/var/log/cloudera-OCI-initialize.log" which contains detailed output from the deployment.

## Destroy the Deployment

When you no longer need the deployment, you can destroy it:

	Terraform Actions -> Destroy

## Deployment Architecture

Here is a diagram showing what is deployed using this template.   Note that resources are automatically distributed among Fault Domains in an Availability Domain to ensure fault tolerance.   Additional workers deployed will stripe between the 3 fault domains in sequence starting with the Fault Domain 1 and incrementing sequentially.

![Deployment Architecture Diagram](https://github.com/oracle/oci-quickstart-cloudera/blob/master/images/deployment_architecture.png)

