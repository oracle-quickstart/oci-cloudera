output "vcn-id" {
	value = "${var.useExistingVcn ? var.myVcn : oci_core_vcn.cloudera_vcn.0.id}"
}

output "private-id" {
	value = "${var.useExistingVcn ? var.clusterSubnet : oci_core_subnet.private.0.id}"
}

output "public-id" {
        value = "${var.useExistingVcn ? var.utilitySubnet : oci_core_subnet.public.0.id}"
}

output "bastion-id" {
        value = "${var.useExistingVcn ? var.bastionSubnet : oci_core_subnet.bastion.0.id}"
}

output "blockvolume-id" {
	value = "${var.useExistingVcn ? var.blockvolumeSubnet : oci_core_subnet.blockvolume.0.id}"
}
