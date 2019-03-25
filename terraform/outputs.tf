output "0 - INFO - Worker Shape" { value = "${var.worker_instance_shape}" }
output "0 - INFO - Block Volume Count" { value = "${ceil(((var.hdfs_usable_in_gbs*3)/var.data_blocksize_in_gbs)/var.worker_node_count)} volumes per worker" }
output "0 - INFO - Block Volume Size (HDFS)" { value = "${var.data_blocksize_in_gbs} GB" }
output "1 - Bastion SSH Login" { value = "ssh -i ${var.ssh_keypath} opc@${data.oci_core_vnic.bastion_vnic.public_ip_address}" }
output "2 - Cloudera Manager URL" { value = "http://${data.oci_core_vnic.utility_node_vnic.public_ip_address}:7180/cmf/" }
output "3 - Cloudera Manager Recent Commands" { value = "http://${data.oci_core_vnic.utility_node_vnic.public_ip_address}:7180/cmf/commands/commands" }
output "4 - DEPLOYMENT COMMAND" { value = "python scripts/deploy_on_oci.py -B -m ${data.oci_core_vnic.utility_node_vnic.public_ip_address} -d ${ceil(((var.hdfs_usable_in_gbs*3)/var.data_blocksize_in_gbs)/var.worker_node_count)} -w ${var.worker_instance_shape}" }
