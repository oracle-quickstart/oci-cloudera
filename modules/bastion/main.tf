resource "oci_core_instance" "Bastion" {
  count               = "${var.instances}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  shape               = "${var.bastion_instance_shape}"
  display_name        = "CDH Bastion ${format("%01d", count.index+1)}"
  fault_domain        = "FAULT-DOMAIN-${(count.index%3)+1}"

  source_details {
    source_type             = "image"
    source_id               = "${var.image_ocid}"
  }

  create_vnic_details {
    subnet_id         = "${var.subnet_id}"
    display_name      = "CDH Bastion ${format("%01d", count.index+1)}"
    hostname_label    = "CDH-Bastion-${format("%01d", count.index+1)}"
    assign_public_ip  = "${var.hide_private_subnet ? true : false}"
  }

  metadata = {
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
  count = "${var.instances}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Bastion ${format("%01d", count.index+1)} Log Data"
  size_in_gbs         = "${var.log_volume_size_in_gbs}"
}

resource "oci_core_volume_attachment" "BastionLogAttachment" {
  count = "${var.instances}"
  attachment_type = "iscsi"
  instance_id     = "${oci_core_instance.Bastion.*.id[count.index]}"
  volume_id       = "${oci_core_volume.BastionLogVolume.*.id[count.index]}"
  device          = "/dev/oracleoci/oraclevdb"
}

# Data Volume for /opt/cloudera
resource "oci_core_volume" "BastionClouderaVolume" {
  count = "${var.instances}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Bastion ${format("%01d", count.index+1)} Cloudera Data"
  size_in_gbs         = "${var.cloudera_volume_size_in_gbs}"
}

resource "oci_core_volume_attachment" "BastionClouderaAttachment" {
  count = "${var.instances}"
  attachment_type = "iscsi"
  instance_id     = "${oci_core_instance.Bastion.*.id[count.index]}"
  volume_id       = "${oci_core_volume.BastionClouderaVolume.*.id[count.index]}"
  device          = "/dev/oracleoci/oraclevdc"
}

