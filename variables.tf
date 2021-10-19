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

variable "blockvolume_cidr" {
  default = "10.0.4.0/24"
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

variable "blockvolume_subnet_id" {
  default = " "
}

variable "worker_domain" {
  default = " "
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
    default = "7.4.4" 
}
# Cloudera Enterprise Data Hub Version
variable "cloudera_version" { 
    default = "7.1.7.0" 
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


// See https://docs.oracle.com/en-us/iaas/images/image/7e0c4acd-2642-4f65-96ff-8c820f206d09/
// Oracle-provided image "Oracle-Linux-7.9-2021.10.04-0"

variable "OELImageOCID" {
  type = "map"
  default = {
    ap-chuncheon-1 = "ocid1.image.oc1.ap-chuncheon-1.aaaaaaaanfughyhlrkcwluddtuisqp5idqhoz2e6yrsmnaxk3b7adlneizkq"
    ap-hyderabad-1 = "ocid1.image.oc1.ap-hyderabad-1.aaaaaaaabdukecj2l3hkplgu3zq7cja7pjqdiiu4vtltzyjwkojw3mqhtfya"
    ap-melbourne-1 = "ocid1.image.oc1.ap-melbourne-1.aaaaaaaaz5bdk2vrwlghroyfmsw22nqso52dsijzfvwyj2jthvekksbtmyra"
    ap-mumbai-1 = "ocid1.image.oc1.ap-mumbai-1.aaaaaaaagwbhu75joxgdn6cwilubuftqiutuy33xxu77c6zemtfldm23eslq"
    ap-osaka-1 = "ocid1.image.oc1.ap-osaka-1.aaaaaaaayq5v6m7qddhnwmdzav3noqanyrssokijolnjwgbewumgno5dg3ra"
    ap-seoul-1 = "ocid1.image.oc1.ap-seoul-1.aaaaaaaa5xfn4bmyde3rpmavpmyordhe6rs4siuquwigkwrtbszlkrjqp45q"
    ap-sydney-1 = "ocid1.image.oc1.ap-sydney-1.aaaaaaaaz5me7ycjpe6orq4xfgbfsvqwrc24ozhhvlpwbophf2qo7fiya44q"
    ap-tokyo-1 = "ocid1.image.oc1.ap-tokyo-1.aaaaaaaajns45jevzrv2ibtn6utyzpqr4oblqiwylzzmc53cshhcsvnt6aha"
    ca-montreal-1 = "ocid1.image.oc1.ca-montreal-1.aaaaaaaaciwparrvtjlonsx2dpzgpb3s27vegtczuw5ww3by6d3sm67nwdxa"
    ca-toronto-1 = "ocid1.image.oc1.ca-toronto-1.aaaaaaaa3hkkn5phegzsh3ikli5ju5ymygp6rqvl7e2ippjbrvtzoooeeumq"
    eu-amsterdam-1 = "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaaufw7ml3y5m46miwihosq7h72o3n6kwndggqzz7edzwbun3ok3ypq"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaanw7ldk5drfpfqtianagutbipglptmu43iwanj2rmdxkqowecvcwa"
    eu-zurich-1 = "ocid1.image.oc1.eu-zurich-1.aaaaaaaa5rdszqyu25mqdnxxgluqeir2xrn2up75o227tnqk6zlp23ly325q"
    me-dubai-1 = "ocid1.image.oc1.me-dubai-1.aaaaaaaahautqpyy47fq4r6ekyzowd623icsat7bl2ya7dxg6dtdl6i424vq"
    me-jeddah-1 = "ocid1.image.oc1.me-jeddah-1.aaaaaaaa4fijw22qksb2xyfmovnoxwp2asxke5ppcg37iqdc6tb43lui2ipa"
    sa-santiago-1 = "ocid1.image.oc1.sa-santiago-1.aaaaaaaajejucvyg7jrsnvdp4jrdxybcfk7wvgn56t544ugh75uuuyor34ha"
    sa-saopaulo-1 = "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaamka2yowr6jcoqdpl5gbaveal4gl3llfqfordz5zqvf2djts4yxra"
    sa-vinhedo-1 = "ocid1.image.oc1.sa-vinhedo-1.aaaaaaaala3gk3rn677mbqxx7s6plka5aztx6msjuzvb6s73wrhe3ckl6zja"
    uk-cardiff-1 = "ocid1.image.oc1.uk-cardiff-1.aaaaaaaavm2td6uswb4mskicwehtznstk36regjn4out5ywqksrekmnepuva"
    uk-london-1 = "ocid1.image.oc1.uk-london-1.aaaaaaaaqetdbotutgsdclw3ainkbcql33qwood6tj4yhq6xfscthtc6akqq"
    us-ashburn-1 = "ocid1.image.oc1.iad.aaaaaaaakjvsts7rf7umrlqtw5hbhc3gjotadu7thfn5cfathwdn3awht7ca"
    us-phoenix-1 = "ocid1.image.oc1.phx.aaaaaaaahmjqvzmd4aja4q5c47ustlgsw23j6afwhsqe5o354bnmdlgleaza"
    us-sanjose-1 = "ocid1.image.oc1.us-sanjose-1.aaaaaaaadthwf7yo6unsgqborhu5yw4klpr5i6ee4j6ipjfablz5kqrbvata"  
  }
}

