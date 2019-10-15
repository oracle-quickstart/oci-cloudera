output "CLOUDERA MANAGER" { value = "http://${module.utility.public-ip}:7180/cmf/" }
output "DEFAULT CLOUDERA MANAGER LOGIN" { value = "User: cdhadmin Password: somepassword" }
