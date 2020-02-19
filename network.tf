
# All regions filtered down to current region
# Example return value [ {"key" = "IAD", "name" = "us-ashburn-1" } ]
data "oci_identity_regions" "filtered_regions" {
  filter {
    name = "name"
    values = [var.region]
  }
}

locals {
  # Construct gateway string from 3 char name of current region
  oci_service_gateway = "all-${lower(data.oci_identity_regions.filtered_regions.regions[0].key)}-services-in-oracle-services-network"
}

module "network" {
	source = "./modules/network"
	tenancy_ocid = "${var.tenancy_ocid}"
	compartment_ocid = "${var.compartment_ocid}"
	availability_domain = "${var.availability_domain}"
	region = "${var.region}"
	oci_service_gateway = "${local.oci_service_gateway}"
	useExistingVcn = "${var.useExistingVcn}"
        VPC_CIDR = "${var.VPC_CIDR}"
	custom_vcn = ["${var.myVcn}"]
}
