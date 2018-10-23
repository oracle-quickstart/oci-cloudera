output "INFO - Data Node Shape" { value = "${var.WorkerInstanceShape}" }
output "1 - Bastion SSH Login" { value = "ssh -i ~/.ssh/id_rsa opc@${data.oci_core_vnic.bastion_vnic.public_ip_address}" }
output "2 - Bastion Commands after SSH login to watch installation process" {
value = <<END

	sudo su -
	screen -r

END
}
output "3 - Cloudera Manager Login Available after ~15m" { value = "http://${data.oci_core_vnic.utility_node_vnic.public_ip_address}:7180/cmf/" }
