# ---------------------------------------------------------------------------------------------------------------------
# Environmental variables
# You probably want to define these as environmental variables.
# Instructions on that are here: https://github.com/oci-quickstart/oci-prerequisites
# ---------------------------------------------------------------------------------------------------------------------

variable "compartment_ocid" {}

# Required by the OCI Provider

variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "ssh_public_key" {}

# ---------------------------------------------------------------------------------------------------------------------
# Optional variables
# You can modify these.
# ---------------------------------------------------------------------------------------------------------------------

variable "availability_domain" {
  default = "2"
}

# Number of Master Nodes in the Cluster
# For Scaling See https://www.cloudera.com/documentation/enterprise/latest/topics/cm_ig_host_allocations.html

variable "master_node_count" {
  default = "2"
}

# Number of Workers in the Cluster

variable "worker_node_count" {
  default = "5"
}

# Size of each Block Volume used for HDFS /data/
# Minimum recommended size is 700GB per Volume to achieve max IOPS/MBps
# Note that total HDFS capacity per worker is limited by this size.  Until Terraform v0.12 is released, 
# this value will likely be static.  Here is a total capacity per worker list for reference:
# 700GB Volume Size = 22.4TB
# 1000GB Volume Size = 32 TB
# 2000GB Volume Size = 64 TB

variable "data_blocksize_in_gbs" {
  default = "700"
}

# Desired HDFS Capacity in GB
# This is used to calcuate number of block volumes per worker.  Adjust data_blocksize_in_gbs as appropriate
# based on number of workers.  For example:
# 5 workers @ 700GB Volume Size = Max HDFS Capacity 112 TB
# 10 workers @ 1TB Volume Size = Max HDFS Capacity 320 TB
# 10 workers @ 2TB Volume Size = Max HDFS Capacity 640 TB
 
variable "hdfs_usable_in_gbs" {
  default = "3000"
}

# Number of Block Volumes per Worker
# Minimum recommended is 3 - Scale up to 32 per compute host
# This is calculated in the template as a factor of DFS replication factor against 
# HDFS Capacity divided by Block Volume size

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

variable "bastion_instance_shape" {
  default = "VM.Standard2.8"
}

variable "master_instance_shape" {
  default = "VM.Standard2.8"
}

variable "worker_instance_shape" {
  default = "BM.DenseIO2.52"
}

# Path to SSH Key

variable "ssh_keypath" {
  default = "/home/opc/.ssh/id_rsa"
}

# ---------------------------------------------------------------------------------------------------------------------
# Constants
# You probably don't need to change these.
# ---------------------------------------------------------------------------------------------------------------------

// See https://docs.us-phoenix-1.oraclecloud.com/images/
// Oracle-provided image "CentOS-7-2019.01.14-0"
// Kernel Version: 3.10.0-957.1.3.el7.x86_64
variable "InstanceImageOCID" {
  type = "map"
  default = {
    ca-toronto-1 = "ocid1.image.oc1.ca-toronto-1.aaaaaaaa5lcszaeld2nl2zo7g3plaxwufz43sftcmuxeimql7kgcczupvn7a"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaay5zmocfjtqjwsdr2vhwcopc32rcz764lsc76crhv2blbyr6azlqq"
    uk-london-1 = "ocid1.image.oc1.uk-london-1.aaaaaaaaz72xqji2opx4dtfmhtlmckna7wg4xr4a2aagh2uywbswhe2vrrja"
    us-ashburn-1 = "ocid1.image.oc1.iad.aaaaaaaaqghm4ftzm2jpwwlcau6hd56josqwm6yvxefvsn25lgmjlchaiuxa"
    us-phoenix-1 = "ocid1.image.oc1.phx.aaaaaaaac5s4dvvtwglae24mbxvfp4fh3ug6ywmlvime2dw62qrjxw3b6fmq"
  }
}

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
