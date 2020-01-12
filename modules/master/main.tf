resource "oci_core_instance" "Master" {
  count               = "${var.instances}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  shape               = "${var.master_instance_shape}"
  display_name        = "Cloudera Master ${format("%01d", count.index+1)}"
  fault_domain	      = "FAULT-DOMAIN-${(count.index%3)+1}"

  source_details {
    source_type             = "image"
    source_id               = "${var.image_ocid}"
  }

  create_vnic_details {
    subnet_id         = "${var.subnet_id}"
    display_name      = "Cloudera Master ${format("%01d", count.index+1)}"
    hostname_label    = "Cloudera-Master-${format("%01d", count.index+1)}"
    assign_public_ip  = "${var.hide_public_subnet ? false : true}"
  }

  metadata = {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data		= "${var.user_data}"
    cloudera_manager    = "${var.cloudera_manager}"
    cloudera_version    = "${var.cloudera_version}"
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
  instance_id     = "${oci_core_instance.Master[count.index].id}"
  volume_id       = "${oci_core_volume.MasterLogVolume[count.index].id}"
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
  instance_id     = "${oci_core_instance.Master[count.index].id}"
  volume_id       = "${oci_core_volume.MasterClouderaVolume[count.index].id}"
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
  instance_id     = "${oci_core_instance.Master[count.index].id}"
  volume_id       = "${oci_core_volume.MasterNNVolume[count.index].id}"
  device          = "/dev/oracleoci/oraclevdd"
}

