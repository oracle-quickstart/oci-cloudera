# ---------------------------------------------------------------------------------------------------------------------
# SSH Keys - Put this to top level because they are required
# ---------------------------------------------------------------------------------------------------------------------

variable "ssh_provided_key" {
  default = ""
}

# ---------------------------------------------------------------------------------------------------------------------
# Network Settings
# ---------------------------------------------------------------------------------------------------------------------
variable "useExistingVcn" {
  default = "false"
}
variable "hide_public_subnet" {
  default = "true"
}
variable "hide_private_subnet" {
  default = "true"
}
variable "VPC_CIDR" {
  default = "10.0.0.0/16"
}
variable "myVcn" {
  default = " "
}

variable "clusterSubnet" {
  default = " "
}

variable "bastionSubnet" {
  default = " "
}

variable "utilitySubnet" {
  default = " "
}

variable "vcn_dns_label" {
  default = "clouderavcn"
}

# ---------------------------------------------------------------------------------------------------------------------
# ORM Schema variables
# You should modify these based on deployment requirements.
# These default to recommended values
# ---------------------------------------------------------------------------------------------------------------------

variable "meta_db_type" {
  default = "mysql"
}

variable "use_edge_nodes" {
  default = "false"
}

variable "enable_block_volumes" {
  default = "true"
}

variable "cm_username" {
  default = "cm_admin"
}

variable "cm_password" {
   default = "changeme"
}

variable "provide_ssh_key" {
  default = "true"
}

variable "vcore_ratio" {
  default = "2"
}

variable "yarn_scheduler" {
  default = "fair"
}

# ---------------------------------------------------------------------------------------------------------------------
# Cloudera variables
# You should modify these based on deployment requirements.
# These default to recommended minimum values in most cases
# ---------------------------------------------------------------------------------------------------------------------

# Cloudera Manager Version
variable "cm_version" {
    default = "7.0.3"
}
# Cloudera Enterprise Data Hub Version
variable "cloudera_version" {
    default = "7.0.3.0"
}
variable "secure_cluster" {
    default = "False"
}

variable "hdfs_ha" {
    default = "False"
}

variable "worker_instance_shape" {
  default = "VM.Standard2.16"
}

variable "worker_node_count" {
  default = "5"
}

variable "data_blocksize_in_gbs" {
  default = "700"
}

variable "block_volumes_per_worker" {
   default = "3"
}

variable "customize_block_volume_performance" {
   default = "false"
}

variable "block_volume_high_performance" {
   default = "false"
}

variable "block_volume_cost_savings" {
   default = "false"
}

variable "vpus_per_gb" {
   default = "10"
}

variable "utility_instance_shape" {
  default = "VM.Standard2.8"
}

variable "master_instance_shape" {
  default = "VM.Standard2.8"
}

variable "master_node_count" {
  default = "2"
}

# Size for Cloudera Log Volumes across all hosts deployed to /var/log/cloudera

variable "log_volume_size_in_gbs" {
  default = "200"
}

# Size for Volume across all hosts deployed to /opt/cloudera

variable "cloudera_volume_size_in_gbs" {
  default = "300"
}

# Size for NameNode and SecondaryNameNode data volume (Journal Data)

variable "nn_volume_size_in_gbs" {
  default = "500"
}

variable "bastion_instance_shape" {
  default = "VM.Standard2.4"
}

variable "bastion_node_count" {
  default = "1"
}

# Which AD to target - this can be adjusted.  Default 1 for single AD regions.
variable "availability_domain" {
  default = "1"
}

variable "cluster_name" {
  default = "TestCluster"
}

variable "objectstoreRAID" {
  default = "false"
}

variable "AdvancedOptions" {
  default = "false"
}

variable "svc_ATLAS" {
  default = "true"
}

variable "svc_HBASE" {
  default = "true"
}

variable "svc_HDFS" {
  default = "true"
}

variable "svc_HIVE" {
  default = "true"
}

variable "svc_IMPALA" {
  default = "true"
}

variable "svc_KAFKA" {
  default = "true"
}

variable "svc_OOZIE" {
  default = "true"
}

variable "svc_RANGER" {
  default = "true"
}

variable "svc_SOLR" {
  default = "true"
}

variable "svc_SPARK_ON_YARN" {
  default = "true"
}

variable "svc_SQOOP_CLIENT" {
  default = "true"
}

variable "svc_YARN" {
  default = "true"
}

variable "rangeradmin_password" {
  default = "Test123!"
}

variable "enable_debug" {
  default = "false"
}
# ---------------------------------------------------------------------------------------------------------------------
# Environmental variables
# You probably want to define these as environmental variables.
# Instructions on that are here: https://github.com/oracle/oci-quickstart-prerequisites
# ---------------------------------------------------------------------------------------------------------------------

variable "compartment_ocid" {}

# Required by the OCI Provider

variable "tenancy_ocid" {}
variable "region" {}

# ---------------------------------------------------------------------------------------------------------------------
# Marketplace Constants
# You probably don't need to change these.
# ---------------------------------------------------------------------------------------------------------------------

variable "mp_listing_id" {
  default = "ocid1.appcataloglisting.oc1..aaaaaaaa3qyy3g2b363sp2rtn6ivdtragtqjvhrg4tx6soiq2eing63snqzq"
}

variable "mp_listing_resource_id" {
  default = "ocid1.image.oc1..aaaaaaaaker4l33357yjn2ktnhmvxzyk5st2c5a5domrnjxcefi2igwgpcrq"
}

variable "mp_listing_resource_version" {
  default = "mkpl-CentOS-7-2019.07.18-0"
}

variable "use_marketplace_image" {
  default = true
}
