# ---------------------------------------------------------------------------------------------------------------------
# Environmental variables
# You probably want to define these as environmental variables.
# Instructions on that are here: https://github.com/oci-quickstart/oci-prerequisites
# ---------------------------------------------------------------------------------------------------------------------

variable "region" {}
variable "compartment_ocid" {}
variable "ssh_public_key" {}
variable "instances" {}
variable "subnet_id" {}
variable "user_data" {}
variable "image_ocid" {}
variable "cm_version" {}
variable "meta_db_type" {}
variable "cloudera_version" {}
variable "worker_shape" {}
variable "block_volume_count" {}
variable "cloudera_manager" {}
variable "cm_install" {}
variable "deploy_on_oci" {}
variable "secure_cluster" {}
variable "hdfs_ha" {} 
variable "cluster_name" {}
variable "hide_private_subnet" {
  default = "true"
}
variable "cluster_subnet" {}
variable "bastion_subnet" {}
variable "utility_subnet" {}
variable "cm_username" {}
variable "cm_password" {}
variable "vcore_ratio" {}
variable "svc_ATLAS" {}
variable "svc_HBASE" {}
variable "svc_HDFS" {}
variable "svc_HIVE" {}
variable "svc_IMPALA" {}
variable "svc_KAFKA" {}
variable "svc_KNOX" {}
variable "svc_OOZIE" {}
variable "svc_RANGER" {}
variable "svc_SOLR" {}
variable "svc_SPARK_ON_YARN" {}
variable "svc_SQOOP_CLIENT" {}
variable "svc_YARN" {}
variable "rangeradmin_password" {}
variable "enable_debug" {}
# ---------------------------------------------------------------------------------------------------------------------
# Optional variables
# You can modify these.
# ---------------------------------------------------------------------------------------------------------------------

variable "availability_domain" {
  default = "2"
}

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

# 
# Set Cluster Shapes in this section
#

variable "utility_instance_shape" {
  default = "VM.Standard2.8"
}

# ---------------------------------------------------------------------------------------------------------------------
# Constants
# You probably don't need to change these.
# ---------------------------------------------------------------------------------------------------------------------
