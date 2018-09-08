resource "oci_dns_zone" "zone1" {
  compartment_id = "${var.compartment_id}"
  name           = "cdsw.cdhvcn.oraclevcn.com"
  zone_type      = "PRIMARY"
}

data "oci_dns_zones" "zs" {
  compartment_id = "${var.compartment_id}"
  name_contains  = "cdh"
  state          = "ACTIVE"
  zone_type      = "PRIMARY"
  sort_by        = "name"
  sort_order     = "DESC"
}

output "zones" {
  value = "${data.oci_dns_zones.zs.zones}"
}

resource "oci_dns_record" "record-a" {
  zone_name_or_id = "${oci_dns_zone.zone1.name}"
  domain          = "${oci_dns_zone.zone1.name}"
  rtype           = "A"
  rdata           = "${data.oci_core_vnic.utility_node_vnic.public_ip_address}"
  ttl             = 3600
}


