data "oci_core_vcn" "vcn_info" {
  vcn_id = "${var.useExistingVcn ? var.myVcn : module.network.vcn-id}" 
}

data "oci_core_subnet" "cluster_subnet" {
  subnet_id = "${var.useExistingVcn ? var.clusterSubnet : module.network.private-id}"
}

data "oci_core_subnet" "bastion_subnet" {
  subnet_id = "${var.useExistingVcn ? var.bastionSubnet : module.network.bastion-id}"
}

data "oci_core_subnet" "utility_subnet" {
  subnet_id = "${var.useExistingVcn ? var.utilitySubnet : module.network.public-id}" 
}

data "null_data_source" "values" {
  inputs = {
    cm_default = "cloudera-utility-1.${data.oci_core_subnet.utility_subnet.dns_label}.${data.oci_core_vcn.vcn_info.vcn_domain_name}"
  }
}

data "null_data_source" "vpus" {
  inputs = {
    block_vpus = "${var.block_volume_high_performance ? 20 : 0}"
  }
}

module "bastion" {
	source	= "./modules/bastion"
	instances = "${var.use_edge_nodes ? var.bastion_node_count : 0}"
	region = "${var.region}"
	compartment_ocid = "${var.compartment_ocid}"
	subnet_id = "${var.useExistingVcn ? var.bastionSubnet : module.network.bastion-id}"
	availability_domain = "${var.availability_domain}"	
	image_ocid = "${var.cloudera_version == "7.0.3.0" ? var.CentOSImageOCID[var.region] : var.OELImageOCID[var.region]}"
	ssh_public_key = "${var.provide_ssh_key ? var.ssh_provided_key : tls_private_key.key.public_key_openssh}"
	bastion_instance_shape = "${var.bastion_instance_shape}" 
        log_volume_size_in_gbs = "${var.log_volume_size_in_gbs}"
        cloudera_volume_size_in_gbs = "${var.cloudera_volume_size_in_gbs}"
	user_data = "${base64encode(file("scripts/boot.sh"))}"
	cloudera_manager = "${data.null_data_source.values.outputs["cm_default"]}"
	cm_version = "${var.cm_version}"
	cloudera_version = "${var.cloudera_version}"
}

module "utility" {
        source  = "./modules/utility"
        instances = "1"
	region = "${var.region}"
	compartment_ocid = "${var.compartment_ocid}"
        subnet_id =  "${var.useExistingVcn ? var.utilitySubnet : module.network.public-id}"
	availability_domain = "${var.availability_domain}"
	image_ocid = "${var.cloudera_version == "7.0.3.0" ? var.CentOSImageOCID[var.region] : var.OELImageOCID[var.region]}"
        ssh_public_key = "${var.provide_ssh_key ? var.ssh_provided_key : tls_private_key.key.public_key_openssh}"
	utility_instance_shape = "${var.utility_instance_shape}"
        log_volume_size_in_gbs = "${var.log_volume_size_in_gbs}"
        cloudera_volume_size_in_gbs = "${var.cloudera_volume_size_in_gbs}"
        user_data = "${base64gzip(file("scripts/cloudera_manager_boot.sh"))}"
	cm_install = "${var.meta_db_type == "mysql" ? base64gzip(file("scripts/cms_mysql.sh")) : base64gzip(file("scripts/cms_postgres.sh"))}"
	deploy_on_oci = "${base64gzip(file("scripts/deploy_on_oci.py"))}"
	cloudera_manager = "${data.null_data_source.values.outputs["cm_default"]}"
        cm_version = "${var.cm_version}"
        cloudera_version = "${var.cloudera_version}"
	worker_shape = "${var.worker_instance_shape}"
	block_volume_count = "${var.enable_block_volumes ? var.block_volumes_per_worker : 0}"
        hdfs_ha = "${var.hdfs_ha}"
	secure_cluster = "${var.secure_cluster}"
	cluster_name = "${var.cluster_name}"
	cluster_subnet = "${data.oci_core_subnet.cluster_subnet.dns_label}"
	bastion_subnet = "${data.oci_core_subnet.bastion_subnet.dns_label}"
	utility_subnet = "${data.oci_core_subnet.utility_subnet.dns_label}"
        meta_db_type = "${var.meta_db_type}"
	cm_username = "${var.cm_username}"
	cm_password = "${var.cm_password}"
        vcore_ratio = "${var.vcore_ratio}"
	svc_ATLAS = "${var.svc_ATLAS}"
	svc_HBASE = "${var.svc_HBASE}"
	svc_HDFS = "${var.svc_HDFS}"
	svc_HIVE = "${var.svc_HIVE}"
	svc_IMPALA = "${var.svc_IMPALA}"
	svc_KAFKA = "${var.svc_KAFKA}"
	svc_OOZIE = "${var.svc_OOZIE}"
	svc_RANGER = "${var.svc_RANGER}"
	svc_SOLR = "${var.svc_SOLR}"
	svc_SPARK_ON_YARN = "${var.svc_SPARK_ON_YARN}"
	svc_SQOOP_CLIENT = "${var.svc_SQOOP_CLIENT}"
	svc_YARN = "${var.svc_YARN}"
	enable_debug = "${var.enable_debug}"
        rangeradmin_password = "${var.rangeradmin_password}"
	yarn_scheduler = "${var.yarn_scheduler}"
}

module "master" {
        source  = "./modules/master"
        instances = "${var.master_node_count}"
	region = "${var.region}"
	compartment_ocid = "${var.compartment_ocid}"
        subnet_id =  "${var.useExistingVcn ? var.clusterSubnet : module.network.private-id}"
	availability_domain = "${var.availability_domain}"
        image_ocid = "${var.cloudera_version == "7.0.3.0" ? var.CentOSImageOCID[var.region] : var.OELImageOCID[var.region]}"
        ssh_public_key = "${var.provide_ssh_key ? var.ssh_provided_key : tls_private_key.key.public_key_openssh}"
	master_instance_shape = "${var.master_instance_shape}"
        log_volume_size_in_gbs = "${var.log_volume_size_in_gbs}"
        cloudera_volume_size_in_gbs = "${var.cloudera_volume_size_in_gbs}"
        user_data = "${base64encode(file("scripts/boot.sh"))}"
	cloudera_manager = "${data.null_data_source.values.outputs["cm_default"]}"
        cm_version = "${var.cm_version}"
        cloudera_version = "${var.cloudera_version}"
}

module "worker" {
        source  = "./modules/worker"
        instances = "${var.worker_node_count}"
	region = "${var.region}"
	compartment_ocid = "${var.compartment_ocid}"
        subnet_id =  "${var.useExistingVcn ? var.clusterSubnet : module.network.private-id}"
	availability_domain = "${var.availability_domain}"
	image_ocid = "${var.cloudera_version == "7.0.3.0" ? var.CentOSImageOCID[var.region] : var.OELImageOCID[var.region]}"
        ssh_public_key = "${var.provide_ssh_key ? var.ssh_provided_key : tls_private_key.key.public_key_openssh}"
	worker_instance_shape = "${var.worker_instance_shape}"
	log_volume_size_in_gbs = "${var.log_volume_size_in_gbs}"
	cloudera_volume_size_in_gbs = "${var.cloudera_volume_size_in_gbs}"
	block_volumes_per_worker = "${var.enable_block_volumes ? var.block_volumes_per_worker : 0}"
	data_blocksize_in_gbs = "${var.data_blocksize_in_gbs}"
        user_data = "${base64encode(file("scripts/boot.sh"))}"
	cloudera_manager = "${data.null_data_source.values.outputs["cm_default"]}"
        cm_version = "${var.cm_version}"
        cloudera_version = "${var.cloudera_version}"
	block_volume_count = "${var.enable_block_volumes ? var.block_volumes_per_worker : 0}"
	vpus_per_gb = "${var.customize_block_volume_performance ? data.null_data_source.vpus.outputs["block_vpus"] : 10}" 
	objectstoreRAID = "${var.objectstoreRAID}"
        enable_secondary_vnic = "${var.enable_secondary_vnic}"
        secondary_vnic_count = "${var.enable_secondary_vnic ? 1 : 0}"
}
