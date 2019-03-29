output "private-id" {
	value = "${oci_core_subnet.private.*.id[var.availability_domain - 1]}"
}

output "public-id" {
        value = "${oci_core_subnet.public.*.id[var.availability_domain - 1]}"
}

output "bastion-id" {
        value = "${oci_core_subnet.bastion.*.id[var.availability_domain - 1]}"
}
