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

variable "custom_cidrs" {
  default = "false"
}

variable "VPC_CIDR" {
  default = "10.0.0.0/16"
}

variable "edge_cidr" {
  default = "10.0.1.0/24"
}

variable "public_cidr" {
  default = "10.0.2.0/24"
}

variable "private_cidr" {
  default = "10.0.3.0/24"
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

variable "blockvolumeSubnet" {
  default = " "
}

variable "vcn_dns_label" { 
  default = "clouderavcn"
}

variable "secondary_vnic_count" {
  default = "0"
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

variable "enable_secondary_vnic" {
  default = "false"
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
    default = "True" 
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
  default = "false"
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
  default = "false"
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
# Constants
# You probably don't need to change these.
# ---------------------------------------------------------------------------------------------------------------------

// See https://docs.cloud.oracle.com/en-us/iaas/images/image/f53b2e1c-a21c-41ab-96b1-18896bdec16f/
// Oracle-provided image "CentOS-7-2019.07.18-0"
// Kernel Version: 3.10.0-957.21.3.el7.x86_64
variable "CentOSImageOCID" {
  type = "map"
  default = {
    ap-mumbai-1 = "ocid1.image.oc1.ap-mumbai-1.aaaaaaaaojdjmlt7hhhyu6ev77fptrpcjza2elnhubmhauxx7ik53g3k4clq"
    ap-seoul-1 = "ocid1.image.oc1.ap-seoul-1.aaaaaaaa2liqaihg2b3dlxl54zqyt7zjvmxdunp6buivbtqhhvurnpepbvta"
    ap-tokyo-1 = "ocid1.image.oc1.ap-tokyo-1.aaaaaaaa7cjkigefv2b3hi32ku4yhwvbtlbn6ektgy25xuopekbcfltequxq"
    ca-toronto-1 = "ocid1.image.oc1.ca-toronto-1.aaaaaaaapgumj7xlcpfqugii7i7y722rfaib7xsc4tnoeikwwtsrrqxzf5qq"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaassfjfflfwty6c24gxoou224djh7rfm3cdnnq5v2jcx6eslwx4fpa"
    eu-zurich-1 = "ocid1.image.oc1.eu-zurich-1.aaaaaaaaqsi7yuqw7jk3wslena3lvpaxrtzpvoz7kelomvpwpdly7me3sixq"
    sa-saopaulo-1 = "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaaanlyfas5floju6eiggf5jqh5oxsaoyjtlziaygabwnklh3gypfva"
    uk-london-1 = "ocid1.image.oc1.uk-london-1.aaaaaaaajyqa7buxw3jkgs5krmxmlnsek24dpby52scb7wsfln55cixusooa"
    us-ashburn-1 = "ocid1.image.oc1.iad.aaaaaaaatp4lxfmhmzebvfsw54tttkiv4jarrohqykbtmee5x2smxlqnr75a"
    us-phoenix-1 = "ocid1.image.oc1.phx.aaaaaaaava2go3l5jvj2ypu6poqgvhzypdwg6qbhkcs5etxewvulgizxy6fa"
  }
}


// See https://docs.cloud.oracle.com/en-us/iaas/images/image/957e74db-0375-4918-b897-a8ce93753ad9/
// Oracle-provided image "Oracle-Linux-7.7-2020.02.21-0"
// Kernel Version: 4.14.35-1902.10.4.el7uek.x86_64 
variable "OELImageOCID" {
  type = "map"
  default = {
    ap-melbourne-1 = "ocid1.image.oc1.ap-melbourne-1.aaaaaaaavpiybmiqoxcohpiih2gasjgqpsiyz4ggylyhhitmrmf3j2ycucrq"
    ap-mumbai-1 = "ocid1.image.oc1.ap-mumbai-1.aaaaaaaarrsp6bazleeeghz6jcifatswozlqkoffzwxzbt2ilj2f65ngqi6a"
    ap-osaka-1 = "ocid1.image.oc1.ap-osaka-1.aaaaaaaafa5rhs2n3dyuncddh5oynk6gisvotvcvch3e6xwplji7phwtbqqa"
    ap-seoul-1 = "ocid1.image.oc1.ap-seoul-1.aaaaaaaadrnhec6655uedkshgcklewzikoqcwr65sevbu27z7vzagniihfha"
    ap-sydney-1 = "ocid1.image.oc1.ap-sydney-1.aaaaaaaaplq4fjdnoooudaqwgzaidh6r3lp3xdhqulx454jivy33t53hokga"
    ap-tokyo-1 = "ocid1.image.oc1.ap-tokyo-1.aaaaaaaa5mpgmnwqwacey5gvczawugmo3ldgrjqnleckmnsokrqytcfkzspa"
    ca-montreal-1 = "ocid1.image.oc1.ca-montreal-1.aaaaaaaaevu23evecil3r23q5illjliinkpyvtkbdq5nsxmcfqypvlewytra"
    ca-toronto-1 = "ocid1.image.oc1.ca-toronto-1.aaaaaaaai25l5mqlzvhjzxvb5n4ullqu333bmalyyg3ki53vt24yn6ld7pra"
    eu-amsterdam-1 = "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaayd4knq4bdh23zqgatgjhoajiz3mx4fy3oy62e5f45ll7trwak5ga"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaa4cmgko5la45jui5cuju7byv6dgnfnjbxhwqxaei3q4zjwlliptuq"
    eu-zurich-1 = "ocid1.image.oc1.eu-zurich-1.aaaaaaaa4nwf5h6nl3u5cdauemg352itja6izecs7ol73z6jftsg4agpdsma"
    me-jeddah-1 = "ocid1.image.oc1.me-jeddah-1.aaaaaaaazrvioeng7va7w4qsuqny4jtxbvnxlf5hu7g2twn6rcwdu35u4riq"
    sa-saopaulo-1 = "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaalfracz4kuew4yxvgydpnbitip6qsreaz7kpxlkr4p67ravvi4jnq"
    uk-gov-london-1 = "ocid1.image.oc4.uk-gov-london-1.aaaaaaaaslh4pip7u6iopbpxujy2twi7diqrs6kfvqfhkl27esdadkqa76mq"
    uk-london-1 = "ocid1.image.oc1.uk-london-1.aaaaaaaa2uwbd457cd2gtviihmxw7cqfmqcug4ahdg7ivgyzla25pgrn6soa"
    us-ashburn-1 = "ocid1.image.oc1.iad.aaaaaaaavzjw65d6pngbghgrujb76r7zgh2s64bdl4afombrdocn4wdfrwdq"
    us-langley-1 = "ocid1.image.oc2.us-langley-1.aaaaaaaauckkms7acrl6to3cuhmv6hfjqwlnoxzuzophaose7pi2sfk4dzna"
    us-luke-1 = "ocid1.image.oc2.us-luke-1.aaaaaaaadxeycutztmvaeefvilc57lfqool2rlgl2r34juyu4jkbodx2xspq"
    us-phoenix-1 = "ocid1.image.oc1.phx.aaaaaaaacy7j7ce45uckgt7nbahtsatih4brlsa2epp5nzgheccamdsea2yq"
  }
}

