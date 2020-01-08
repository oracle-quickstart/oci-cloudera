data "oci_identity_availability_domains" "ADs" {
  count = var.useExistingVcn ? 0 : 1
  compartment_id = "${var.tenancy_ocid}"
}

data "oci_core_services" "all_svcs_moniker" {
  count = var.useExistingVcn ? 0 : 1
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}
