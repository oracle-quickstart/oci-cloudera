# oci-cloudera-edh
These are Terraform modules for deploying Cloudera Enterprise Data Hub (EDH) on Oracle Cloud Infrastructure (OCI):

* [Sandbox](Sandbox) deploys a single instance running the Cloudera Docker container.  This is a good fit for individuals who want to explore Cloudera on OCI at a very low cost. |                  
* [Development](Development) is the next step up and deploys five instances.
* [Production](Production) is the most powerful preconfigured option.  It provides high density, high performance and high availability.  It is an appropriate entry point for scaling up a production big data practice. |
* [N-Node](N-Node) deploys a cluster of arbitrary size.
* [AD-Spanning](AD-Spanning) is a variation of the N-Node deployment that spans all ADs in a region.  This provides the most highly available solution for running Cloudera EDH on OCI.

## How to use these Modules
In addition to an active tenancy on OCI, you will need a functional installation of Terraform, and an API key for a privileged user in the tenancy.  See these documentation links for more information:

* [Getting Started with Terraform on OCI](https://docs.cloud.oracle.com/iaas/Content/API/SDKDocs/terraformgetstarted.htm)
* [How to Generate an API Signing Key](https://docs.cloud.oracle.com/iaas/Content/API/Concepts/apisigningkey.htm#How)

Once the prerequisites are in place, you will need to copy the templates from this repository to where you have Terraform installed.
