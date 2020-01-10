resource "tls_private_key" "key" {
  algorithm = "RSA"
}

resource "local_file" "key_file" { 
	filename = "${path.module}/key.pem"
	content = "${tls_private_key.key.private_key_pem}"
}
