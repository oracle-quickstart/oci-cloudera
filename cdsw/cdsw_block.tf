# Block Device for CDSW

resource "oci_core_volume" "CDSW" {
  count = "1"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "CDH CDSW Block for Docker"
  size_in_gbs = "1024"
}


resource "oci_core_volume_attachment" "CDSW" {
  count = "1"
  attachment_type = "iscsi"
  compartment_id = "${var.compartment_ocid}"
  instance_id = "${oci_core_instance.UtilityNode.*.id[0]}"
  volume_id = "${oci_core_volume.UtilityNode.id}"
}


