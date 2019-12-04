module "network" { 
	source = "./modules/network"
	tenancy_ocid = "${var.tenancy_ocid}"
	compartment_ocid = "${var.compartment_ocid}"
        adnumber = "${var.adnumber}"
	availability_domain = "${var.availability_domain}"
	region = "${var.region}"
	oci_service_gateway = "${var.oci_service_gateway[var.region]}"
	useExistingVcn = "${var.useExistingVcn}"
        VPC_CIDR = "${var.VPC_CIDR}"
	vcnId = "${var.myVcn}"
}
