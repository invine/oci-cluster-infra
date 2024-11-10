resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

# Define a ClusterIssuer for Let's Encrypt Staging
resource "kubectl_manifest" "letsencrypt_issuer" {
  yaml_body  = <<EOF
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
  EOF
  depends_on = [helm_release.cert_manager]
}
