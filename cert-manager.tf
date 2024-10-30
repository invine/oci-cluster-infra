resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  #   version    = "v1.16.1" # Use the latest version from https://artifacthub.io/packages/helm/cert-manager/cert-manager
  namespace = "cert-manager"

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [
    oci_containerengine_cluster.k8s_cluster,
    local_file.k8s_cluster_kube_config_file,
    oci_containerengine_node_pool.oke-node-pool,
    helm_release.nginx_ingress,
    kubernetes_namespace.cert_manager
  ]
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

# Define a ClusterIssuer for Let's Encrypt Staging
resource "kubectl_manifest" "letsencrypt_issuer" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ${var.lets_encrypt_issuer_name} # Replace with actual issuer name if needed
spec:
  acme:
    server: ${var.lets_encrypt_issuer_server} # Replace with actual server URL if needed
    email: ${var.lets_encrypt_email} # Replace with actual email if needed
    privateKeySecretRef:
      name: ${var.lets_encrypt_issuer_name}-account-key # Secret to store private key
    solvers:
      - http01:
          ingress:
            ingressClassName: nginx # Update with your ingress class
  YAML
  # {
  #   "apiVersion" = "cert-manager.io/v1"
  #   "kind"       = "ClusterIssuer"
  #   "metadata" = {
  #     "name" = var.lets_encrypt_issuer_name
  #   }
  #   "spec" = {
  #     "acme" = {
  #       "server" = var.lets_encrypt_issuer_server
  #       "email"  = var.lets_encrypt_email
  #       "privateKeySecretRef" = {
  #         "name" = "${var.lets_encrypt_issuer_name}-account-key" # Secret to store private key
  #       }
  #       "solvers" = [
  #         {
  #           "http01" = {
  #             "ingress" = {
  #               "ingressClassName" = "nginx" # Update with your ingress class
  #             }
  #           }
  #           # "dns01" = {
  #           #   "webhook" : {
  #           #     "config" : {
  #           #       "apiTokenSecretRef" : {
  #           #         "key" : "token",
  #           #         "name" : "duckdns-token"
  #           #       }
  #           #     },
  #           #     "groupName" : "everk8s.duckdns.org",
  #           #     "solverName" : "duckdns"
  #           #   }
  #           # }
  #         }
  #       ]
  #     }
  #   }
  # }

  depends_on = [
    helm_release.cert_manager,
    oci_containerengine_cluster.k8s_cluster,
    local_file.k8s_cluster_kube_config_file,
    oci_containerengine_node_pool.oke-node-pool,
    helm_release.nginx_ingress,
    kubernetes_namespace.cert_manager,
    helm_release.cert_manager
  ]
}
