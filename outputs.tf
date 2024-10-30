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

output "argocd_admin_password" {
  value     = data.kubernetes_secret.argocd_admin_secret.data["password"]
  sensitive = true
}

output "nginx_ingress_controller_loadbalancer_hostname" {
  value = data.kubernetes_service.nginx_ingress_controller.status[0].load_balancer[0].ingress[0].hostname
}

output "nginx_ingress_controller_loadbalancer_ip" {
  value = data.kubernetes_service.nginx_ingress_controller.status[0].load_balancer[0].ingress[0].ip
}
