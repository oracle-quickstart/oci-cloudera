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
    cm_default = "cdh-utility-1.${data.oci_core_subnet.utility_subnet.dns_label}.${data.oci_core_vcn.vcn_info.vcn_domain_name}"
  }
}

module "bastion" {
	source	= "./modules/bastion"
	instances = "${var.bastion_node_count}"
	region = "${var.region}"
	compartment_ocid = "${var.compartment_ocid}"
	subnet_id = "${var.useExistingVcn ? var.bastionSubnet : module.network.bastion-id}"
	availability_domain = "${var.availability_domain}"	
	image_ocid = "${var.InstanceImageOCID[var.region]}"
        ssh_private_key = "${var.ssh_private_key}"
	ssh_public_key = "${var.ssh_public_key}"
	bastion_instance_shape = "${var.bastion_instance_shape}" 
        log_volume_size_in_gbs = "${var.log_volume_size_in_gbs}"
        cloudera_volume_size_in_gbs = "${var.cloudera_volume_size_in_gbs}"
	user_data = "${base64encode(file("scripts/boot.sh"))}"
	cloudera_manager = "${data.null_data_source.values.outputs["cm_default"]}"
	cm_version = "${var.cm_version}"
	cdh_version = "${var.cdh_version}"
}

module "utility" {
        source  = "./modules/utility"
        instances = "1"
	region = "${var.region}"
	compartment_ocid = "${var.compartment_ocid}"
        subnet_id =  "${var.useExistingVcn ? var.utilitySubnet : module.network.public-id}"
	availability_domain = "${var.availability_domain}"
	image_ocid = "${var.InstanceImageOCID[var.region]}"
	ssh_private_key = "${var.ssh_private_key}"
        ssh_public_key = "${var.ssh_public_key}"
        utility_instance_shape = "${var.utility_instance_shape}"
        log_volume_size_in_gbs = "${var.log_volume_size_in_gbs}"
        cloudera_volume_size_in_gbs = "${var.cloudera_volume_size_in_gbs}"
        user_data = "${base64gzip(file("scripts/cloudera_manager_boot.sh"))}"
	cm_install = "${var.meta_db_type == "mysql" ? base64gzip(file("scripts/cms_mysql.sh")) : base64gzip(file("scripts/cms_postgres.sh"))}"
	deploy_on_oci = "${base64gzip(file("scripts/deploy_on_oci.py"))}"
	cloudera_manager = "${data.null_data_source.values.outputs["cm_default"]}"
        cm_version = "${var.cm_version}"
        cdh_version = "${var.cdh_version}"
	worker_shape = "${var.worker_instance_shape}"
	block_volume_count = "${var.block_volumes_per_worker}"
        hdfs_ha = "${var.hdfs_ha}"
	secure_cluster = "${var.secure_cluster}"
	cluster_name = "${var.cluster_name}"
	cluster_subnet = "${data.oci_core_subnet.cluster_subnet.dns_label}"
	bastion_subnet = "${data.oci_core_subnet.bastion_subnet.dns_label}"
	utility_subnet = "${data.oci_core_subnet.utility_subnet.dns_label}"
        meta_db_type = "${var.meta_db_type}"
}

module "master" {
        source  = "./modules/master"
        instances = "${var.master_node_count}"
	region = "${var.region}"
	compartment_ocid = "${var.compartment_ocid}"
        subnet_id =  "${var.useExistingVcn ? var.clusterSubnet : module.network.private-id}"
	availability_domain = "${var.availability_domain}"
        image_ocid = "${var.InstanceImageOCID[var.region]}"
        ssh_private_key = "${var.ssh_private_key}"
        ssh_public_key = "${var.ssh_public_key}"
        master_instance_shape = "${var.master_instance_shape}"
        log_volume_size_in_gbs = "${var.log_volume_size_in_gbs}"
        cloudera_volume_size_in_gbs = "${var.cloudera_volume_size_in_gbs}"
        user_data = "${base64encode(file("scripts/boot.sh"))}"
	cloudera_manager = "${data.null_data_source.values.outputs["cm_default"]}"
        cm_version = "${var.cm_version}"
        cdh_version = "${var.cdh_version}"
}

module "worker" {
        source  = "./modules/worker"
        instances = "${var.worker_node_count}"
	region = "${var.region}"
	compartment_ocid = "${var.compartment_ocid}"
        subnet_id =  "${var.useExistingVcn ? var.clusterSubnet : module.network.private-id}"
	availability_domain = "${var.availability_domain}"
	image_ocid = "${var.InstanceImageOCID[var.region]}"
        ssh_private_key = "${var.ssh_private_key}"
        ssh_public_key = "${var.ssh_public_key}"
        worker_instance_shape = "${var.worker_instance_shape}"
	log_volume_size_in_gbs = "${var.log_volume_size_in_gbs}"
	cloudera_volume_size_in_gbs = "${var.cloudera_volume_size_in_gbs}"
	block_volumes_per_worker = "${var.block_volumes_per_worker}"
	data_blocksize_in_gbs = "${var.data_blocksize_in_gbs}"
        user_data = "${base64encode(file("scripts/boot.sh"))}"
	cloudera_manager = "${data.null_data_source.values.outputs["cm_default"]}"
        cm_version = "${var.cm_version}"
        cdh_version = "${var.cdh_version}"
	block_volume_count = "${var.block_volumes_per_worker}"
	objectstoreRAID = "${var.objectstoreRAID}"
}
