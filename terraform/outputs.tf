output "DEPLOYMENT_COMMAND" { value = "python ../scripts/deploy_on_oci.py -B -m ${module.utility.public-ip} -d ${module.worker.block-volume-count} -w ${var.worker_instance_shape}" }
