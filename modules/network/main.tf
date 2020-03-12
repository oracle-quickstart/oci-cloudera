resource "oci_core_vcn" "cloudera_vcn" {
  count = var.useExistingVcn ? 0 : 1
  cidr_block     = "${var.VPC_CIDR}"
  compartment_id = "${var.compartment_ocid}"
  display_name   = "cloudera_vcn"
  dns_label      = "${var.vcn_dns_label}"
}

resource "oci_core_internet_gateway" "cloudera_internet_gateway" {
  count = var.useExistingVcn ? 0 : 1
  compartment_id = "${var.compartment_ocid}"
  display_name   = "cloudera_internet_gateway"
  vcn_id         = "${var.useExistingVcn ? var.custom_vcn[0] : oci_core_vcn.cloudera_vcn.0.id}"
}

resource "oci_core_nat_gateway" "nat_gateway" {
  count = var.useExistingVcn ? 0 : 1
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${var.useExistingVcn ? var.custom_vcn[0] : oci_core_vcn.cloudera_vcn.0.id}"
  display_name   = "nat_gateway"
}

resource "oci_core_service_gateway" "cloudera_service_gateway" {
  count = var.useExistingVcn ? 0 : 1
  compartment_id = "${var.compartment_ocid}"
  services {
    service_id = "${lookup(data.oci_core_services.all_svcs_moniker[count.index].services[0], "id")}"
  }
  vcn_id = "${var.useExistingVcn ? var.custom_vcn[0] : oci_core_vcn.cloudera_vcn.0.id}"
  display_name = "Cloudera Service Gateway"
}

resource "oci_core_route_table" "RouteForComplete" {
  count = var.useExistingVcn ? 0 : 1
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${var.useExistingVcn ? var.custom_vcn[0] : oci_core_vcn.cloudera_vcn.0.id}"
  display_name   = "RouteTableForComplete"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = "${oci_core_internet_gateway.cloudera_internet_gateway.*.id[count.index]}"
  }
}

resource "oci_core_route_table" "private" {
  count = var.useExistingVcn ? 0 : 1
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${var.useExistingVcn ? var.custom_vcn[0] : oci_core_vcn.cloudera_vcn.0.id}"
  display_name   = "private"

  route_rules {
      destination       = "${var.oci_service_gateway}"
      destination_type  = "SERVICE_CIDR_BLOCK"
      network_entity_id = "${oci_core_service_gateway.cloudera_service_gateway.*.id[count.index]}"
    }
  
  route_rules {
      destination       = "0.0.0.0/0"
      destination_type  = "CIDR_BLOCK"
      network_entity_id = "${oci_core_nat_gateway.nat_gateway.*.id[count.index]}"
    }
}

resource "oci_core_security_list" "PublicSubnet" {
  count = var.useExistingVcn ? 0 : 1
  compartment_id = "${var.compartment_ocid}"
  display_name   = "Public Subnet"
  vcn_id         = "${var.useExistingVcn ? var.custom_vcn[0] : oci_core_vcn.cloudera_vcn.0.id}"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"
  }

  ingress_security_rules {
    tcp_options {
      max = 7180
      min = 7180
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  }
  ingress_security_rules {
    tcp_options {
      max = 18088
      min = 18088
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  }
  ingress_security_rules {
    tcp_options {
      max = 19888
      min = 19888
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  }
  ingress_security_rules {
    tcp_options {
      max = 22
      min = 22
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  }
  ingress_security_rules {
    protocol = "6"
    source   = "${var.VPC_CIDR}"
  }
}

resource "oci_core_security_list" "PrivateSubnet" {
  count = var.useExistingVcn ? 0 : 1
  compartment_id = "${var.compartment_ocid}"
  display_name   = "Private"
  vcn_id         = "${var.useExistingVcn ? var.custom_vcn[0] : oci_core_vcn.cloudera_vcn.0.id}"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"
  }
  egress_security_rules {
    protocol    = "6"
    destination = "${var.VPC_CIDR}"
  }

  ingress_security_rules {
    protocol = "6"
    source   = "${var.VPC_CIDR}"
  }
}

resource "oci_core_security_list" "BastionSubnet" {
  count = var.useExistingVcn ? 0 : 1
  compartment_id = "${var.compartment_ocid}"
  display_name   = "Bastion"
  vcn_id         = "${var.useExistingVcn ? var.custom_vcn[0] : oci_core_vcn.cloudera_vcn.0.id}"

  egress_security_rules {
    protocol    = "6"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    tcp_options {
      max = 22
      min = 22
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  }
  ingress_security_rules {
      protocol = "6"
      source   = "${var.VPC_CIDR}"
    }
}

resource "oci_core_subnet" "public" {
  count = var.useExistingVcn ? 0 : 1
  availability_domain = "${var.availability_domain}"
  cidr_block          = "${var.custom_cidrs ? var.public_cidr : cidrsubnet(var.VPC_CIDR, 8, 1)}"
  display_name        = "public"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${var.useExistingVcn ? var.custom_vcn[0] : oci_core_vcn.cloudera_vcn.0.id}"
  route_table_id      = "${oci_core_route_table.RouteForComplete[count.index].id}"
  security_list_ids   = ["${oci_core_security_list.PublicSubnet.*.id[count.index]}"]
  dhcp_options_id     = "${oci_core_vcn.cloudera_vcn[count.index].default_dhcp_options_id}"
  dns_label           = "public"
}

resource "oci_core_subnet" "private" {
  count = var.useExistingVcn ? 0 : 1
  availability_domain = "${var.availability_domain}"
  cidr_block          = "${var.custom_cidrs ? var.private_cidr : cidrsubnet(var.VPC_CIDR, 8, 2)}"
  display_name        = "private"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${var.useExistingVcn ? var.custom_vcn[0] : oci_core_vcn.cloudera_vcn.0.id}"
  route_table_id      = "${oci_core_route_table.private[count.index].id}"
  security_list_ids   = ["${oci_core_security_list.PrivateSubnet.*.id[count.index]}"]
  dhcp_options_id     = "${oci_core_vcn.cloudera_vcn[count.index].default_dhcp_options_id}"
  prohibit_public_ip_on_vnic = "true"
  dns_label = "private"
}

resource "oci_core_subnet" "bastion" {
  count = var.useExistingVcn ? 0 : 1
  availability_domain = "${var.availability_domain}"
  cidr_block          = "${var.custom_cidrs ? var.edge_cidr : cidrsubnet(var.VPC_CIDR, 8, 3)}"
  display_name        = "bastion"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${var.useExistingVcn ? var.custom_vcn[0] : oci_core_vcn.cloudera_vcn.0.id}"
  route_table_id      = "${oci_core_route_table.RouteForComplete[count.index].id}"
  security_list_ids   = ["${oci_core_security_list.BastionSubnet.*.id[count.index]}"]
  dhcp_options_id     = "${oci_core_vcn.cloudera_vcn[count.index].default_dhcp_options_id}"
  dns_label           = "bastion"
}
