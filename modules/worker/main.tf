resource "oci_core_instance" "Worker" {
  count               = "${var.instances}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  shape               = "${var.worker_instance_shape}"
  display_name        = "Cloudera Worker ${format("%01d", count.index+1)}"
  fault_domain        = "FAULT-DOMAIN-${(count.index%3)+1}"

  source_details {
    source_type             = "image"
    source_id               = "${var.image_ocid}"
  }

  create_vnic_details {
    subnet_id          = "${var.subnet_id}"
    display_name        = "Cloudera Worker ${format("%01d", count.index+1)}"
    hostname_label      = "Cloudera-Worker-${format("%01d", count.index+1)}"
    assign_public_ip  = "${var.hide_public_subnet ? false : true}"
  }

  metadata = {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data		= "${var.user_data}"
    cloudera_manager    = "${var.cloudera_manager}"
    cloudera_version    = "${var.cloudera_version}"
    cm_version          = "${var.cm_version}" 
    block_volume_count  = "${var.block_volume_count}"
    objectstoreRAID     = "${var.objectstoreRAID}"
  }

  timeouts {
    create = "30m"
  }
}
// Block Volume Creation for Worker 

# Log Volume for /var/log/cloudera
resource "oci_core_volume" "WorkerLogVolume" {
  count               = "${var.instances}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Cloudera Worker  ${format("%01d", count.index+1)} Log Data"
  size_in_gbs         = "${var.log_volume_size_in_gbs}"
}

resource "oci_core_volume_attachment" "WorkerLogAttachment" {
  count           = "${var.instances}"
  attachment_type = "iscsi"
  instance_id     = "${oci_core_instance.Worker[count.index].id}"
  volume_id       = "${oci_core_volume.WorkerLogVolume[count.index].id}"
  device          = "/dev/oracleoci/oraclevdb"
}

# Data Volume for /opt/cloudera
resource "oci_core_volume" "WorkerClouderaVolume" {
  count               = "${var.instances}"
  availability_domain = "${var.availability_domain}"  
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Cloudera Worker ${format("%01d", count.index+1)} Cloudera Data"
  size_in_gbs         = "${var.cloudera_volume_size_in_gbs}"
}

resource "oci_core_volume_attachment" "WorkerClouderaAttachment" {
  count           = "${var.instances}"
  attachment_type = "iscsi"
  instance_id     = "${oci_core_instance.Worker[count.index].id}"
  volume_id       = "${oci_core_volume.WorkerClouderaVolume[count.index].id}"
  device          = "/dev/oracleoci/oraclevdc"
}

# RAID Volumes for Object Store Cache
resource "oci_core_volume" "WorkerRAIDVolume" {
  count               = var.objectstoreRAID ? (var.instances * 4) : 0
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Cloudera Worker ${format("%01d", floor((count.index / 4)+1))} RAID ${format("%01d", floor((count.index%(4))+1))}"
  size_in_gbs         = 700
}

resource "oci_core_volume_attachment" "WorkerRAIDAttachment" {
  count               = var.objectstoreRAID ? (var.instances * 4) : 0
  attachment_type = "iscsi"
  instance_id     = "${oci_core_instance.Worker[floor(count.index/4)].id}"
  volume_id       = "${oci_core_volume.WorkerRAIDVolume[count.index].id}"
  device = "${var.data_volume_attachment_device[floor(count.index%(4))]}"
}

# Data Volumes for HDFS
resource "oci_core_volume" "WorkerDataVolume" {
  count               = "${(var.instances * var.block_volumes_per_worker)}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Cloudera Worker ${format("%01d", floor((count.index / var.block_volumes_per_worker)+1))} HDFS Data ${format("%01d", floor((count.index%(var.block_volumes_per_worker))+1))}"
  size_in_gbs         = "${var.data_blocksize_in_gbs}"
  vpus_per_gb         = "${var.vpus_per_gb}"
}

resource "oci_core_volume_attachment" "WorkerDataAttachment" {
  count               = "${(var.instances * var.block_volumes_per_worker)}"
  attachment_type = "iscsi"
  instance_id     = "${oci_core_instance.Worker[floor(count.index/var.block_volumes_per_worker)].id}"
  volume_id       = "${oci_core_volume.WorkerDataVolume[count.index].id}"
  device = "${var.objectstoreRAID ? var.data_volume_attachment_device[(floor(count.index%(var.block_volumes_per_worker))+4)] : var.data_volume_attachment_device[floor(count.index%(var.block_volumes_per_worker))]}"
}

