resource "oci_core_instance" "Bastion" {
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "CDH Bastion"
  hostname_label      = "CDH-Bastion"
  shape               = "${var.bastion_instance_shape}"
  subnet_id	      = "${var.subnet_id}"

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
// Block Volume Creation for Bastion 

# Log Volume for /var/log/cloudera
resource "oci_core_volume" "BastionLogVolume" {
  count               = "1"
  availability_domain = "${var.availability_domain}"
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
  availability_domain = "${var.availability_domain}"
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

