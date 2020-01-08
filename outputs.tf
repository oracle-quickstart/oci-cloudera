output "CLOUDERA_MANAGER" { value = "http://${module.utility.public-ip}:7180/cmf/" }
output "DEFAULT_CLOUDERA_MANAGER_LOGIN" { value = "User: cdhadmin Password: somepassword" }
