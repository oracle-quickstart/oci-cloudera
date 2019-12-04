output "private-id" {
	value = "${oci_core_subnet.private.0.id}"
}

output "public-id" {
        value = "${oci_core_subnet.public.0.id}"
}

output "bastion-id" {
        value = "${oci_core_subnet.bastion.0.id}"
}

