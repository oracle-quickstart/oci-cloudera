# development
This is for small implementations.  This deployment consists of five instances:

* 1 Bastion Instance
* 1 Utility Instance
* 3 worker Nodes

This environment provides a much higher HDFS storage capacity, along with a compute and memory resources for use with a variety of big data workloads.   This environment is not a good fit for users who want high availability.

|             | Worker Nodes                                       | Bastion Instance | Utility Instance |
|-------------|----------------------------------------------------|------------------|------------------|
| Minimum     | BM.Standard1.16 with 3x700GB Block Storage Devices | VM.Standard1.4   | VM.Standard1.8   |                   
| Recommended | BM.Standard2.24 with 3x1TB Block Storage Devices   | VM.Standard2.4   | VM.Standard2.8   |

## Prerequisites
Installation has a dependency on Terraform being installed and configured for the user tenancy.  As such an `env-vars` file is included with this package that contains all the necessary environment variables.  This file should be updated with the appropriate values prior to installation.  To source this file prior to installation, either reference it in your .rc file for your shell's or run the following:

    source env-vars

## Password and User Details
Modify the script `startup.sh` and look for the `MAIN CLUSTER CONFIGURATION` section - this is which you can input your contact information, and set up the Cloudera Manager credentials prior to deployment.

## Deployment
Deploy using standard Terraform commands

    terraform init
    terraform plan
    terraform apply

## Post Deployment
Post deployment is automated using a scripted process that uses the Bash and Cloudera Manager API via Python.  Clusters are preconfigured with tunings based around instance type (in the `cmx.py` script).  Log in to the Bastion host after Terraform completes, then run the following commands to watch installation progress.  The public IP will output as a result of the Terraform completion:

    ssh -i ~/.ssh/id_rsa opc@<public_ip_of_bastion>
    sudo su -
    screen -r

Cluster provisioning can take up to half an hour.  After SCM setup is complete, you can monitor progress  directly using the Cloudera Manager UI.  The URL for this is also output as part of the Terraform provisioning process.

## Security and Post-Deployment Auditing
Note that as part of this deployment, ssh keys are used for root level access to provisioned hosts in order to setup software.  The key used is the same as the OPC user which has super-user access to the hosts by default.  If enhanced security is desired, then the following steps should be taken after the Cluster is up and running:

Remove ssh private keys from Utility host:

    rm -f /home/opc/.ssh/id_rsa

Replace the authorized_keys file in `/root/.ssh/` on all hosts with the backup copy

    sudo mv /root/.ssh/authorized_keys.bak /root/.ssh/authorized_keys
