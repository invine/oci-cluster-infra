resource "tls_private_key" "worker_node_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
