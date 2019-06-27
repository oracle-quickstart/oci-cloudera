output "private-id" {
	value = "${oci_core_subnet.private.*.id}"
}

output "public-id" {
        value = "${oci_core_subnet.public.*.id}"
}

output "bastion-id" {
        value = "${oci_core_subnet.bastion.*.id}"
}

output "vcn-dn" {
	value = "${oci_core_vcn.cloudera_vcn.dns_label}.oraclevcn.com"
}
