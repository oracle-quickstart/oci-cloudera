# ---------------------------------------------------------------------------------------------------------------------
# Cloudera variables
# You should modify these based on deployment requirements.
# These default to recommended minimum values in most cases
# ---------------------------------------------------------------------------------------------------------------------
# Cloudera Manager Version
variable "cm_version" { 
    default = "6.2.0" 
}
# Cloudera Enterprise Data Hub Version
variable "cdh_version" { 
    default = "6.2.0" 
}
# Deployment type - set this to "secure" to enable Kerberos and High Availability
variable "deployment_type" { 
    default = "simple" 
}

variable "worker_instance_shape" {
  default = "BM.DenseIO2.52"
}

variable "worker_node_count" {
  default = "3"
}

variable "data_blocksize_in_gbs" {
  default = "700"
}

variable "block_volumes_per_worker" {
   default = "3"
}

variable "utility_instance_shape" {
  default = "VM.Standard2.16"
}

variable "master_instance_shape" {
  default = "VM.Standard2.16"
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

# Which AD to target
variable "availability_domain" {
  default = "1"
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
variable "ssh_public_key" {}
variable "ssh_private_key" {}
variable "AD" {
    default="1"
}

# ---------------------------------------------------------------------------------------------------------------------
# Constants
# You probably don't need to change these.
# ---------------------------------------------------------------------------------------------------------------------

// See https://docs.us-phoenix-1.oraclecloud.com/images/
// Oracle-provided image "Oracle-Linux-7.6-2019.05.28-0"
// Kernel Version: 4.14.35-1844.5.3
variable "InstanceImageOCID" {
  type = "map"
  default = {
    ap-seoul-1 = "ocid1.image.oc1.ap-seoul-1.aaaaaaaa6mmih5n72yviujadzfkzthjwyc3h5uvaeejc3kpalhyakk6tfejq"
    ap-tokyo-1 = "ocid1.image.oc1.ap-tokyo-1.aaaaaaaayxjigcwqiqjncbkm7yxppjqfzsjnbvtjsemrvnwrtpwynausossa"
    ca-toronto-1 = "ocid1.image.oc1.ca-toronto-1.aaaaaaaabmpm76byqi5nisxblvh4gtfvfxbnyo4vmoqfvpldggellgrv4eiq"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaijslwo4cd3xhcledgwglqwjem3te4q3szekfm37hoo3wf2tm6u5a"
    uk-london-1 = "ocid1.image.oc1.uk-london-1.aaaaaaaa66i5ug2lc6ywq6j2y4e535vgzsgb7pwn6blv2bw5a2wb2gbo5wfa"
    us-ashburn-1 = "ocid1.image.oc1.iad.aaaaaaaaj6pcmnh6y3hdi3ibyxhhflvp3mj2qad4nspojrnxc6pzgn2w3k5q"
    us-phoenix-1 = "ocid1.image.oc1.phx.aaaaaaaa2wadtmv6j6zboncfobau7fracahvweue6dqipmcd5yj6s54f3wpq"
  }
}

variable "oci_service_gateway" {
  type = "map"
  default = {
    ap-seoul-1 = "all-icn-services-in-oracle-services-network"
    ap-tokyo-1 = "all-nrt-services-in-oracle-serviecs-network"
    ca-toronto-1 = "all-yyz-services-in-oracle-services-network"
    eu-frankfurt-1 = "all-fra-services-in-oracle-services-network"
    uk-london-1 = "all-lhr-services-in-oracle-services-network"
    us-ashburn-1 = "all-iad-services-in-oracle-services-network"
    us-phoenix-1 = "all-phx-services-in-oracle-services-network"
  }
}
