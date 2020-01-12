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
variable "cloudera_version" {}
variable "cloudera_manager" {}
variable "block_volume_count" {}
variable "hide_public_subnet" {
  default = "true"
}
variable "objectstoreRAID" {
  default = "false"
}
# ---------------------------------------------------------------------------------------------------------------------
# Optional variables
# You can modify these.
# ---------------------------------------------------------------------------------------------------------------------

variable "availability_domain" {
  default = "2"
}

# Number of Workers in the Cluster

variable "worker_node_count" {
  default = "5"
}

# Size of each Block Volume used for HDFS /data/
# Minimum recommended size is 700GB per Volume to achieve max IOPS/MBps
# Note that total HDFS capacity per worker is limited by this size.  U
# Here is a total capacity per worker list for reference (using 30 volumes per worker):
# 700GB Volume Size = 21 TB per worker
# 1000GB Volume Size = 30 TB per worker
# 2000GB Volume Size = 60 TB per worker

variable "data_blocksize_in_gbs" {
  default = "700"
}

# Number of Block Volumes per Worker
# Minimum recommended is 3 - Scale up to 32 per compute host
# 5 workers @ 700GB Volume Size = Max HDFS Capacity 105 TB, 35 TB Usable with 3x Replication
# 10 workers @ 1TB Volume Size = Max HDFS Capacity 300 TB, 100 TB Usable with 3x Replication
# 10 workers @ 2TB Volume Size = Max HDFS Capacity 600 TB, 200 TB Usable with 3x Replication
# If using DenseIO local storage only - set this to '0'
# If using Heterogenous storage, this will add Block Volume capacity on top of Local storage.
# When using Heterogenous storage - be sure to modify the deploy_on_oci.py and set data_tiering flag to 'True'

variable "block_volumes_per_worker" {
   default = "3"
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

# 
# Set Cluster Shapes in this section
#

variable "worker_instance_shape" {
  default = "BM.DenseIO2.52"
}


# ---------------------------------------------------------------------------------------------------------------------
# Constants
# You probably don't need to change these.
# ---------------------------------------------------------------------------------------------------------------------

// Volume Mapping - used to map Worker Block Volumes consistently to the OS
variable "data_volume_attachment_device" {
  type = "map"
  default = {
    "0" = "/dev/oracleoci/oraclevdd"
    "1" = "/dev/oracleoci/oraclevde"
    "2" = "/dev/oracleoci/oraclevdf"
    "3" = "/dev/oracleoci/oraclevdg"
    "4" = "/dev/oracleoci/oraclevdh"
    "5" = "/dev/oracleoci/oraclevdi"
    "6" = "/dev/oracleoci/oraclevdj"
    "7" = "/dev/oracleoci/oraclevdk"
    "8" = "/dev/oracleoci/oraclevdl"
    "9" = "/dev/oracleoci/oraclevdm"
    "10" = "/dev/oracleoci/oraclevdn"
    "11" = "/dev/oracleoci/oraclevdo"
    "12" = "/dev/oracleoci/oraclevdp"
    "13" = "/dev/oracleoci/oraclevdq"
    "14" = "/dev/oracleoci/oraclevdr" 
    "15" = "/dev/oracleoci/oraclevds"
    "16" = "/dev/oracleoci/oraclevdt"
    "17" = "/dev/oracleoci/oraclevdu"
    "18" = "/dev/oracleoci/oraclevdv"
    "19" = "/dev/oracleoci/oraclevdw"
    "20" = "/dev/oracleoci/oraclevdx"
    "21" = "/dev/oracleoci/oraclevdy"
    "22" = "/dev/oracleoci/oraclevdz"
    "23" = "/dev/oracleoci/oraclevdab"
    "24" = "/dev/oracleoci/oraclevdac"
    "25" = "/dev/oracleoci/oraclevdad"
    "26" = "/dev/oracleoci/oraclevdae" 
    "27" = "/dev/oracleoci/oraclevdaf"
    "28" = "/dev/oracleoci/oraclevdag"
  }
}

