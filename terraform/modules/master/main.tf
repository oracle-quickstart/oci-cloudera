resource "oci_core_instance" "Master" {
  count               = "${var.instances}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "CDH Master ${format("%01d", count.index+1)}"
  hostname_label      = "CDH-Master-${format("%01d", count.index+1)}"
  shape               = "${var.master_instance_shape}"
  subnet_id           = "${var.subnet_id}"
  fault_domain	      = "FAULT-DOMAIN-${(count.index%3)+1}"

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
  }

  timeouts {
    create = "30m"
  }
}

// Block Volume Creation for Master 

# Log Volume for /var/log/cloudera
resource "oci_core_volume" "MasterLogVolume" {
  count               = "${var.instances}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Cloudera Master ${format("%01d", count.index+1)} Log Data"
  size_in_gbs         = "${var.log_volume_size_in_gbs}"
}

resource "oci_core_volume_attachment" "MasterLogAttachment" {
  count           = "${var.instances}"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.Master.*.id[count.index]}"
  volume_id       = "${oci_core_volume.MasterLogVolume.*.id[count.index]}"
  device          = "/dev/oracleoci/oraclevdb"
}

# Data Volume for /opt/cloudera
resource "oci_core_volume" "MasterClouderaVolume" {
  count               = "${var.instances}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Cloudera Master ${format("%01d", count.index+1)} Cloudera Data"
  size_in_gbs         = "${var.cloudera_volume_size_in_gbs}"
}

resource "oci_core_volume_attachment" "MasterClouderaAttachment" {
  count           = "${var.instances}"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.Master.*.id[count.index]}"
  volume_id       = "${oci_core_volume.MasterClouderaVolume.*.id[count.index]}"
  device          = "/dev/oracleoci/oraclevdc"
}

# Data Volume for /data (Name & SecondaryName)
resource "oci_core_volume" "MasterNNVolume" {
  count               = "${var.instances}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Cloudera Master ${format("%01d", count.index+1)} Journal Data"
  size_in_gbs         = "${var.nn_volume_size_in_gbs}"
}

resource "oci_core_volume_attachment" "MasterNNAttachment" {
  count           = "${var.instances}"
  attachment_type = "iscsi"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${oci_core_instance.Master.*.id[count.index]}"
  volume_id       = "${oci_core_volume.MasterNNVolume.*.id[count.index]}"
  device          = "/dev/oracleoci/oraclevdd"
}

