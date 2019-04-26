# ---------------------------------------------------------------------------------------------------------------------
# Environmental variables
# You probably want to define these as environmental variables.
# Instructions on that are here: https://github.com/oci-quickstart/oci-prerequisites
# ---------------------------------------------------------------------------------------------------------------------

variable "region" {}
variable "compartment_ocid" {}
variable "private_key_path" {}
variable "ssh_public_key" {}
variable "ssh_private_key" {}
variable "instances" {}
variable "subnet_id" {}
variable "user_data" {}

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

variable "master_instance_shape" {
  default = "VM.Standard2.8"
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
// Oracle-provided image "Oracle-Linux-7.6-2019.03.22-1"
// Kernel Version: 4.14.35-1844.3.2.el7uek.x86_64
variable "InstanceImageOCID" {
  type = "map"
  default = {
    ca-toronto-1 = "ocid1.image.oc1.ca-toronto-1.aaaaaaaaqopv4wgbh54jrqoa4bjpkng2y2npzoe2jaj5pdne37ljdxbbbdka"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaa2n5z4nmkqjf27btkbdibflwvximz5i3rsz57c3gowckozrdshnua"
    uk-london-1 = "ocid1.image.oc1.uk-london-1.aaaaaaaaaxnnrqke453ur5katouvfn2i6oweuwpixx6mm5e4nqtci7oztx5a"
    us-ashburn-1 = "ocid1.image.oc1.iad.aaaaaaaavxqdkuyamlnrdo3q7qa7q3tsd6vnyrxjy3nmdbpv7fs7um53zh5q"
    us-phoenix-1 = "ocid1.image.oc1.phx.aaaaaaaapxvrtwbpgy3lchk2usn462ekarljwg4zou2acmundxlkzdty4bjq"
  }
}

