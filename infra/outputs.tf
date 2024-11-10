output "compartment-OCID" {
  value = oci_identity_compartment.k8s_compartment.id
}

# Outputs for the vcn module
output "vcn_id" {
  description = "OCID of the VCN that is created"
  value       = module.vcn.vcn_id
}

output "worker_node_private_key" {
  value     = tls_private_key.worker_node_ssh_key.private_key_openssh
  sensitive = true
}

output "worker_node_public_key" {
  value     = tls_private_key.worker_node_ssh_key.public_key_openssh
  sensitive = true
}
