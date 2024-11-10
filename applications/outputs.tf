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
