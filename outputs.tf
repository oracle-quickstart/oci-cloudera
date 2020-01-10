output "CLOUDERA_INFO" { value = "Cluster Builds can take anywhere from 15 to 30 minutes depending on deployment options.  It is recommended to wait at least 15 minutes before logging into Cloudera Manager.   Deployment progress can be checked on the Utility host in /var/log/cloudera-OCI-initialize.log" }
output "CLOUDERA_MANAGER" { value = "http://${module.utility.public-ip}:7180/cmf/" }
output "CLOUDERA_MANAGER_LOGIN" { value = "User: ${var.cm_username} Password: ${var.cm_password}" }
output "SSH_KEY_INFO" { value = "${var.provide_ssh_key ? "SSH Key Provided by user" : "See below for generated SSH private key."}" }
output "SSH_PRIVATE_KEY" { value = "${var.provide_ssh_key ? "SSH Key Provided by user" : tls_private_key.key.private_key_pem}" }
