output "bastion-ssh" { value = "ssh -i ${var.ssh_keypath} opc@${data.oci_core_vnic.bastion_vnic.public_ip_address}" }
