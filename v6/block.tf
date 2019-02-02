// Block Volume Creation for Bastion 

# Log Volume for /var/log/cloudera
resource "oci_core_volume" "BastionLogVolume" {
  count               = "1"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Bastion ${format("%01d", count.index+1)} Log Data"
  size_in_gbs         = "${var.log_volume_size_in_gbs}"
}

resource "oci_core_volume_attachment" "BastionLogAttachment" {
  count           = "1"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.Bastion.id}"
  volume_id       = "${oci_core_volume.BastionLogVolume.id}"
  device          = "/dev/oracleoci/oraclevdb"
}

# Data Volume for /opt/cloudera
resource "oci_core_volume" "BastionClouderaVolume" {
  count               = "1"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Bastion ${format("%01d", count.index+1)} Cloudera Data"
  size_in_gbs         = "${var.cloudera_volume_size_in_gbs}"
}

resource "oci_core_volume_attachment" "BastionClouderaAttachment" {
  count           = "1"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.Bastion.id}"
  volume_id       = "${oci_core_volume.BastionClouderaVolume.id}"
  device          = "/dev/oracleoci/oraclevdc"
}

// Block Volume Creation for Utility 

# Log Volume for /var/log/cloudera
resource "oci_core_volume" "UtilLogVolume" {
  count               = "1"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Cloudera Manager ${format("%01d", count.index+1)} Log Data"
  size_in_gbs         = "${var.log_volume_size_in_gbs}"
}

resource "oci_core_volume_attachment" "UtilLogAttachment" {
  count           = "1"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.Utility.id}"
  volume_id       = "${oci_core_volume.UtilLogVolume.id}"
  device          = "/dev/oracleoci/oraclevdb"
}

# Data Volume for /opt/cloudera
resource "oci_core_volume" "UtilClouderaVolume" {
  count               = "1"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Cloudera Manager ${format("%01d", count.index+1)} Data"
  size_in_gbs         = "${var.cloudera_volume_size_in_gbs}"
}

resource "oci_core_volume_attachment" "UtilClouderaAttachment" {
  count           = "1"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.Utility.id}"
  volume_id       = "${oci_core_volume.UtilClouderaVolume.id}"
  device          = "/dev/oracleoci/oraclevdc"
}


// Block Volume Creation for Master 

# Log Volume for /var/log/cloudera
resource "oci_core_volume" "MasterLogVolume" {
  count               = "${var.master_node_count}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Cloudera Master ${format("%01d", count.index+1)} Log Data"
  size_in_gbs         = "${var.log_volume_size_in_gbs}"
}

resource "oci_core_volume_attachment" "MasterLogAttachment" {
  count           = "${var.master_node_count}"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.Master.*.id[count.index]}"
  volume_id       = "${oci_core_volume.MasterLogVolume.*.id[count.index]}"
  device          = "/dev/oracleoci/oraclevdb"
}

# Data Volume for /opt/cloudera
resource "oci_core_volume" "MasterClouderaVolume" {
  count               = "${var.master_node_count}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Cloudera Master ${format("%01d", count.index+1)} Cloudera Data"
  size_in_gbs         = "${var.cloudera_volume_size_in_gbs}"
}

resource "oci_core_volume_attachment" "MasterClouderaAttachment" {
  count           = "1"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.Master.*.id[count.index]}"
  volume_id       = "${oci_core_volume.MasterClouderaVolume.*.id[count.index]}"
  device          = "/dev/oracleoci/oraclevdc"
}

# Data Volume for /data (Name & SecondaryName)
resource "oci_core_volume" "MasterNNVolume" {
  count               = "${var.master_node_count}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Cloudera Master ${format("%01d", count.index+1)} Journal Data"
  size_in_gbs         = "${var.nn_volume_size_in_gbs}"
}

resource "oci_core_volume_attachment" "MasterNNAttachment" {
  count           = "${var.master_node_count}"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.Master.*.id[count.index]}"
  volume_id       = "${oci_core_volume.MasterNNVolume.*.id[count.index]}"
  device          = "/dev/oracleoci/oraclevdd"
}

// Block Volume Creation for Worker 

# Log Volume for /var/log/cloudera
resource "oci_core_volume" "WorkerLogVolume" {
  count               = "${var.worker_node_count}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Cloudera Worker  ${format("%01d", count.index+1)} Log Data"
  size_in_gbs         = "${var.log_volume_size_in_gbs}"
}

resource "oci_core_volume_attachment" "WorkerLogAttachment" {
  count           = "${var.worker_node_count}"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.Worker.*.id[count.index]}"
  volume_id       = "${oci_core_volume.WorkerLogVolume.*.id[count.index]}"
  device          = "/dev/oracleoci/oraclevdb"
}

# Data Volume for /opt/cloudera
resource "oci_core_volume" "WorkerClouderaVolume" {
  count               = "${var.worker_node_count}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Cloudera Worker ${format("%01d", count.index+1)} Cloudera Data"
  size_in_gbs         = "${var.cloudera_volume_size_in_gbs}"
}

resource "oci_core_volume_attachment" "WorkerClouderaAttachment" {
  count           = "${var.worker_node_count}"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.Worker.*.id[count.index]}"
  volume_id       = "${oci_core_volume.WorkerClouderaVolume.*.id[count.index]}"
  device          = "/dev/oracleoci/oraclevdc"
}

# Data Volumes for HDFS
resource "oci_core_volume" "WorkerDataVolume" {
  count               = "${var.worker_node_count * (ceil(((var.hdfs_usable_in_gbs*3)/var.data_blocksize_in_gbs)/var.worker_node_count))}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Cloudera Worker ${format("%01d", (count.index / (ceil(((var.hdfs_usable_in_gbs*3)/var.data_blocksize_in_gbs)/var.worker_node_count)))+1)} HDFS Data ${format("%01d", (count.index%((ceil(((var.hdfs_usable_in_gbs*3)/var.data_blocksize_in_gbs))/var.worker_node_count)))+1)}"
  size_in_gbs         = "${var.data_blocksize_in_gbs}"
}

resource "oci_core_volume_attachment" "WorkerDataAttachment" {
  count           = "${var.worker_node_count * (ceil(((var.hdfs_usable_in_gbs*3)/var.data_blocksize_in_gbs)/var.worker_node_count))}"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.Worker.*.id[count.index / (ceil(((var.hdfs_usable_in_gbs*3)/var.data_blocksize_in_gbs)/var.worker_node_count))]}"
  volume_id       = "${oci_core_volume.WorkerDataVolume.*.id[count.index]}"
  device 	  = "${var.data_volume_attachment_device[count.index%(ceil(((var.hdfs_usable_in_gbs*3)/var.data_blocksize_in_gbs)/var.worker_node_count))]}"
}

