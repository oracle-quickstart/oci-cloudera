output "block-volume-count" { value = "${ceil(((var.hdfs_usable_in_gbs*3)/var.data_blocksize_in_gbs)/var.worker_node_count)}" }
output "block-volume-size" { value = "${var.data_blocksize_in_gbs}" }
