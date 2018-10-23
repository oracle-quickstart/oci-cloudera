# oci-cloudera-edh
These are Terraform modules for deploying Cloudera Enterprise Data Hub (EDH) on Oracle Cloud Infrastructure (OCI).

## Sandbox

[Sandbox](Sandbox) is a good starting point.  This module deploys a single instance running the Cloudera Docker container.  This is a good fit for individuals who want to explore Cloudera on OCI at a very low cost.  This is not a good fit for multiple users, development efforts, or large datasets.

## Development
For small implementations, [Development](Development) is the next step up.  This deployment consists of five instances:

* 1 Bastion Instance
* 1 Utility Instance
* 3 worker Nodes

This environment provides a much higher HDFS storage capacity, along with a compute and memory resources for use with a variety of big data workloads.   This environment is not a good fit for users who want high availability.

|             | Worker Nodes                                       | Bastion Instance | Utility Instance |
|-------------|----------------------------------------------------|------------------|------------------|
| Minimum     | BM.Standard1.16 with 3x700GB Block Storage Devices | VM.Standard1.4   | VM.Standard1.8   |                   
| Recommended | BM.Standard2.24 with 3x1TB Block Storage Devices   | VM.Standard2.4   | VM.Standard2.8   |

## Production
[Production](Production) is the most powerful preconfigured option.  It provides high density, high performance and high availability.  It is an appropriate entry point for scaling up a production big data practice.

|             | Worker Nodes   | Bastion Instance         | Utility and Master Instances |
|-------------|----------------|--------------------------|------------------------------|
| Minimum     | BM.DenseIO1.36 | VM.Standard1.4           | VM.Standard1.8               |                                
| Recommended | BM.DenseIO2.52 | VM.Standard2.4           | VM.Standard2.8               |                                   

## N-Node
With the [N-Node](N-Node) module it's possible to deploy a cluster of arbitrary size.

|             | Worker Nodes   | Bastion Instance | Utility and Master Instances |
|-------------|----------------|------------------|------------------------------|
| Minimum     | BM.DenseIO1.36 | VM.Standard1.4   | VM.Standard1.8               |
| Recommended | BM.DenseIO2.52 | VM.Standard2.4   | VM.Standard2.16              |

## AD-Spanning
[AD-Spanning](AD-Spanning) is a variation of the N-Node deployment that spans all ADs in a region.  This provides the most highly available solution for running Cloudera EDH on OCI.

## Scripts
[Scripts](scripts) are bash scripts that the modules in this repo share.  They are run via both cloud-init and remote exec to install and configure EDH.

## How to use these templates
In addition to an active tenancy on OCI, you will need a functional installation of Terraform, and an API key for a privileged user in the tenancy.  See these documentation links for more information:

* [Getting Started with Terraform on OCI](https://docs.cloud.oracle.com/iaas/Content/API/SDKDocs/terraformgetstarted.htm)
* [How to Generate an API Signing Key](https://docs.cloud.oracle.com/iaas/Content/API/Concepts/apisigningkey.htm#How)

Once the prerequisites are in place, you will need to copy the templates from this repository to where you have Terraform installed.
