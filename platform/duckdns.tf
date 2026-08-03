resource "null_resource" "duckdns_update" {
  # Create a null resource to trigger the DuckDNS update after external ip is assigned to ingress
  depends_on = [helm_release.nginx_ingress]

  provisioner "local-exec" {
    command = <<EOT
      curl -X GET "https://www.duckdns.org/update?domains=${var.duckdns_subdomain}&token=${var.duckdns_token}&ip=${data.kubernetes_service.nginx_ingress_controller.status[0].load_balancer[0].ingress[0].ip}"
    EOT
  }
}
