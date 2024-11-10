resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    <<EOF
  configs:
    params:
      server.insecure: true
  server:
    ingress:
      enabled: true
      ingressClassName: nginx
      hostname: argocd.${var.duckdns_subdomain}.duckdns.org
      tls: true
      annotations:
        acme.cert-manager.io/http01-edit-in-place: "true" # important to merge with existing ingress resource into a single nginx config file
        cert-manager.io/cluster-issuer: ${var.lets_encrypt_issuer_name}
  EOF
  ]
}

resource "kubernetes_secret" "argocd_repo_secret" {
  metadata {
    name      = var.argocd_bootstrap_repo_name
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    url     = var.argocd_bootstrap_repo_url
    type    = "git"
    project = "default"
  }

  type = "Opaque"

  depends_on = [
    helm_release.argocd,
    kubectl_manifest.letsencrypt_issuer
  ]
}

resource "kubectl_manifest" "argocd_bootstrap_applications" {
  yaml_body  = <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argocd-bootstrap
  namespace: ${kubernetes_namespace.argocd.metadata[0].name} # Replace with actual namespace if needed
spec:
  project: default
  source:
    repoURL: ${var.argocd_bootstrap_repo_url} # Replace with actual URL if needed
    path: ${var.argocd_bootstrap_repo_app_path} # Replace with actual path if needed
    targetRevision: ${var.argocd_bootstrap_repo_branch} # Replace with actual branch if needed
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
  depends_on = [helm_release.argocd]
}

data "kubernetes_secret" "argocd_admin_secret" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }
  depends_on = [kubernetes_secret.argocd_repo_secret]
}
