resource "oci_core_instance" "Worker" {
  count               = "${var.instances}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "CDH Worker ${format("%01d", count.index+1)}"
  hostname_label      = "CDH-Worker-${format("%01d", count.index+1)}"
  shape               = "${var.worker_instance_shape}"
  subnet_id           = "${var.subnet_id}"
  fault_domain        = "FAULT-DOMAIN-${(count.index%3)+1}"

  source_details {
    source_type             = "image"
    source_id               = "${var.image_ocid}"
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data		= "${var.user_data}"
    cloudera_manager    = "${var.cloudera_manager}"
    cdh_version         = "${var.cdh_version}"
    cm_version          = "${var.cm_version}" 
    block_volume_count  = "${var.block_volume_count}"
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
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.Worker.*.id[count.index]}"
  volume_id       = "${oci_core_volume.WorkerLogVolume.*.id[count.index]}"
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
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.Worker.*.id[count.index]}"
  volume_id       = "${oci_core_volume.WorkerClouderaVolume.*.id[count.index]}"
  device          = "/dev/oracleoci/oraclevdc"
}

# Data Volumes for HDFS
resource "oci_core_volume" "WorkerDataVolume" {
  count               = "${(var.instances * var.block_volumes_per_worker)}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Cloudera Worker ${format("%01d", (count.index / var.block_volumes_per_worker)+1)} HDFS Data ${format("%01d", (count.index%(var.block_volumes_per_worker))+1)}"
  size_in_gbs         = "${var.data_blocksize_in_gbs}"
}

resource "oci_core_volume_attachment" "WorkerDataAttachment" {
  count               = "${(var.instances * var.block_volumes_per_worker)}"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.Worker.*.id[count.index/var.block_volumes_per_worker]}"
  volume_id       = "${oci_core_volume.WorkerDataVolume.*.id[count.index]}"
  device = "${var.data_volume_attachment_device[count.index%(var.block_volumes_per_worker)]}"
}

