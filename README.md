# oci-cloudera
This module deploys a cluster of arbitrary size on [Oracle Cloud Infrastructure](https://cloud.oracle.com/en_US/iaas) using [Cloudera Enterprise Data Hub](https://www.cloudera.com/products/enterprise-data-hub.html) v6 and Cloudera Manager v6.1.

Future development will include support for EDH v5 clusters.  In the meantime, use the [1.0.0 release](https://github.com/oci-quickstart/oci-cloudera/releases/tag/1.0.0) for v5 deployments.

|             | Worker Nodes   | Bastion Instance | Utility and Master Instances |
|-------------|----------------|------------------|------------------------------|
| Recommended | BM.DenseIO2.52 | VM.Standard2.4   | VM.Standard2.16              |
| Minimum     | VM.Standard2.8 | VM.Standard2.1   | VM.Standard2.8               |

Host types can be customized in this template.   Also included with this template is an easy method to customize block volume quantity and size as pertains to HDFS capacity.   See "variables.tf" for more information in-line.

## Prerequisites
First off you'll need to do some pre deploy setup.  That's all detailed [here](https://github.com/oci-quickstart/oci-prerequisites).

### Additional Python Dependencies
This module depends on Python, Paramiko, PIP, and cm_client.   These should be installed on the host you are using to deploy the Terraform module.  

On EL7 hosts, installation can be performed using the following commands:

	sudo yum install python python-pip python-paramiko.noarch -y
	sudo pip install --upgrade pip
	sudo pip install cm_client

On Mac, installation can be peformed using the following commands:

	curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
	sudo python get-pip.py
	sudo pip install --upgrade pip
	sudo pip install cm_client paramiko

### Clone the Module
Now, you'll want a local copy of this repo.  You can make that with the commands:

    git clone https://github.com/oci-quickstart/oci-cloudera.git
    cd oci-cloudera
    ls

## Python Deployment using cm_client
The deployment script "deploy_on_oci.py" uses cm_client against Cloudera Manger API v31.  As such it does require some customization before execution.  Reference the header section in the script, it is highly encouraged you modify the following variables before deployment, ssh_keyfile is required or deployment will fail:

	admin_user_name
	admin_password
	cluster_name
	ssh_keyfile (REQUIRED)
	cluster_service_list

Also if you modify the compute.tf in any way to change hostname parameters, you will need to update these variables for pattern matching, otherwise host detection and cluster layout will fail:

	worker_hosts_contain
	master_hosts_contain
	namenode_host_contains
	secondary_namenode_host_contains
	cloudera_manager_host_contains

In addition, further customization of the cluster deployment can be done by modification of the following functions:

	setup_mgmt_rcg
	update_cluster_rcg_configuration

This does require some knowledge of Python - modify at your own risk.  These functions contain Cloudera specific tuning parameters as well as host mapping for roles.

## Kerberos Secure Cluster by Default

This automation now defaults to using a local KDC deployed on the Cloudera Manager instance for secure cluster operation.  Please read the scripts [README](https://github.com/oci-quickstart/oci-cloudera/blob/master/scripts/README.md) for information regarding how to set these parameters prior to deployment.

Also - for cluster management, you will need to manually create at a minimum the HDFS Superuser Principal as [detailed here](https://www.cloudera.com/documentation/enterprise/latest/topics/cm_sg_using_cm_sec_config.html#create-hdfs-superuser) after deployment.

## Cloudera Manager and Cluster Metadata Database
You are able to customize which database you want to use for Cloudera Manager and Cluster Metadata.   In compute.tf you will see a "user_data" field for the Utility instance:

	user_data           = "${base64encode(file("scripts/cm_boot_mysql.sh"))}"

This is set to use MySQL for the database.  If you want to use Postgres, you would change it:

	user_data           = "${base64encode(file("scripts/cm_boot_postgres.sh"))}"

You can customize the default root password for MySQL by editing the source script.  For the various Cloudera databases, random passwords are generated and used.  The same is true when using Postgres.

Note that you will also need to change "meta_db_port" in deploy_on_oci.py if you choose to run Postgres.

## Object Storage Integration
As of the 2.1.0 release, included with this template is a means to deploy clusters with configuration to allow use of OCI Object Storage using S3 Compatability.  In order to implement, an S3 Access and Secret key must be set up in the OCI Tenancy first.  This process is detailed [here](https://docs.cloud.oracle.com/iaas/Content/Identity/Tasks/managingcredentials.htm#Working2).  Once that is in place, modify the [deploy_on_oci.py](https://github.com/oci-quickstart/oci-cloudera/blob/master/scripts/deploy_on_oci.py#L133-L141) script, and set the following values:

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

This will create all the required elements in a compartment in the target OCI tenancy.  This includes VCN and Security List parameters.  Security audit of these in the network.tf is suggested.

After Terraform is finished deploying, the output will show the Python syntax to trigger cluster deployment.  This command can be run immediately following deployment, as it has built-in checks to wait until Cloudera Manager API is up and responding before it executes deployment.  The syntax is as follows:

	python scripts/deploy_on_oci.py -B -m <master_ip> -d <disk_count> -w <worker_shape>

It is also possible to destroy an existing cluster with this script using Cloudera Manager

	python scripts/deploy_on_oci.py -D -m <master_ip>

## Destroy the Deployment

When you no longer need the deployment, you can run this command to destroy it:

	terraform destroy

## Deployment Caveats
Currently this module requires Cloudera Manager API to be on an edge host with a Public IP address.   This is used to trigger cluster deployment, as well as SSH into the Cloudera Manger host to perform dynamic host discovery to map for Cluster topology.   

Future enhancements to this module are planned to support a completely Private (non-Internet exposed) cluster deployment.
