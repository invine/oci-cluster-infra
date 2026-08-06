resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = concat([
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
    ], var.argocd_version == "7.6.12" ? [] : [
    <<EOF
  crds:
    install: true
    keep: true
  EOF
  ])

  depends_on = [
    helm_release.nginx_ingress,
    kubectl_manifest.letsencrypt_issuer,
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
    url  = var.argocd_bootstrap_repo_url
    type = "git"
  }

  type = "Opaque"

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_bootstrap_applications" {
  yaml_body = <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argocd-bootstrap
  namespace: ${kubernetes_namespace.argocd.metadata[0].name}
spec:
  project: default
  source:
    repoURL: ${var.argocd_bootstrap_repo_url}
    path: ${var.argocd_bootstrap_repo_path}
    targetRevision: ${var.argocd_bootstrap_repo_branch}
    directory:
      recurse: true
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
  depends_on = [
    helm_release.argocd,
    kubernetes_secret.argocd_repo_secret,
  ]
}

data "kubernetes_secret" "argocd_admin_secret" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }
  depends_on = [kubernetes_secret.argocd_repo_secret]
}
