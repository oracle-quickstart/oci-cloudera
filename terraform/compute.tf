resource "oci_core_instance" "Utility" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "CDH Utility-1"
  hostname_label      = "CDH-Utility-1"
  shape               = "${var.master_instance_shape}"
  subnet_id           = "${oci_core_subnet.public.*.id[var.availability_domain - 1]}"
  fault_domain	      = "FAULT-DOMAIN-3"

  source_details {
    source_type             = "image"
    source_id               = "${var.InstanceImageOCID[var.region]}"
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data           = "${base64encode(file("../scripts/cm_boot_mysql.sh"))}"
  }

  timeouts {
    create = "30m"
  }
}

resource "oci_core_instance" "Master" {
  depends_on	      = ["oci_core_instance.Utility"]
  count               = "${var.master_node_count}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "CDH Master ${format("%01d", count.index+1)}"
  hostname_label      = "CDH-Master-${format("%01d", count.index+1)}"
  shape               = "${var.master_instance_shape}"
  subnet_id           = "${oci_core_subnet.private.*.id[var.availability_domain - 1]}"
  fault_domain	      = "FAULT-DOMAIN-${(count.index%3)+1}"

  source_details {
    source_type             = "image"
    source_id               = "${var.InstanceImageOCID[var.region]}"
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data           = "${base64encode(file("../scripts/boot.sh"))}"
  }

  timeouts {
    create = "30m"
  }
}

resource "oci_core_instance" "Bastion" {
  depends_on          = ["oci_core_instance.Utility"]
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "CDH Bastion"
  hostname_label      = "CDH-Bastion"
  shape               = "${var.bastion_instance_shape}"
  subnet_id           = "${oci_core_subnet.bastion.*.id[var.availability_domain - 1]}"

  source_details {
    source_type             = "image"
    source_id               = "${var.InstanceImageOCID[var.region]}"
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data           = "${base64encode(file("../scripts/boot.sh"))}"
  }

  timeouts {
    create = "30m"
  }
}

resource "oci_core_instance" "Worker" {
  depends_on          = ["oci_core_instance.Utility"]
  count               = "${var.worker_node_count}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "CDH Worker ${format("%01d", count.index+1)}"
  hostname_label      = "CDH-Worker-${format("%01d", count.index+1)}"
  shape               = "${var.worker_instance_shape}"
  subnet_id           = "${oci_core_subnet.private.*.id[var.availability_domain - 1]}"
  fault_domain        = "FAULT-DOMAIN-${(count.index%3)+1}"

  source_details {
    source_type             = "image"
    source_id               = "${var.InstanceImageOCID[var.region]}"
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data           = "${base64encode(file("../scripts/boot.sh"))}"
  }

  timeouts {
    create = "30m"
  }
}
