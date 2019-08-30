output "cm-url" { value = "http://${data.oci_core_vnic.utility_node_vnic.public_ip_address}:7180/cmf/" }
output "cm-commands-url" { value = "http://${data.oci_core_vnic.utility_node_vnic.public_ip_address}:7180/cmf/commands/commands" }
output "public-ip" { value = "${data.oci_core_vnic.utility_node_vnic.public_ip_address}" }
