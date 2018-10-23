# oci-cloudera-edh
These are Terraform modules for deploying Cloudera Enterprise Data Hub (EDH) on Oracle Cloud Infrastructure (OCI):

* [sandbox](sandbox) deploys a single instance running the Cloudera Docker container.  This is a good fit for people who want to explore Cloudera on OCI at a very low cost.
* [development](development) is the next step up and deploys five instances.
* [production](production) is the most powerful preconfigured option.  It provides high density, high performance and high availability.  It is an appropriate entry point for scaling up a production big data practice.
* [n-node](n-node) deploys a cluster of arbitrary size.
* [ad-spanning](ad-spanning) is a variation of the N-Node deployment that spans all ADs in a region.  This provides the most highly available solution for running Cloudera EDH on OCI.

## Prerequisites
First off you'll need to do some pre deploy setup.  That's all detailed [here](https://github.com/cloud-partners/oci-prerequisites).

## Clone the Module
Now, you'll want a local copy of this repo.  You can make that with the commands:

    git clone https://github.com/cloud-partners/oci-cloudera-edh.git
    cd oci-couchbase/terraform
    ls

## Deploy
Pick a module and `cd` into the directory containing it.  You can deploy with the following Terraform commands:

    terraform init
    terraform plan
    terraform apply

When complete, Terraform will print information on how you can access the deployment.

## Destroy the Deployment
When you no longer need the deployment, you can run this command to destroy it:

    terraform destroy
