output "CLOUDERA_MANAGER" { value = "http://${module.utility.public-ip}:7180/cmf/" }
output "CLOUDERA_MANAGER_LOGIN" { value = "User: ${var.cm_username} Password: ${var.cm_password}" }
