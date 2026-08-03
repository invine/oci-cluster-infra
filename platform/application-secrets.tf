locals {
  application_namespaces = [
    "echo",
    "openvpn",
    "staging",
    "vaultwarden",
  ]
}

# The Bootstrap Seed owns Application Namespace lifecycle. This bounded gate
# lets a single platform apply wait for Argo CD before creating Explicit Secrets.
resource "terraform_data" "application_namespaces_ready" {
  triggers_replace = local.application_namespaces

  provisioner "local-exec" {
    command = "kubectl wait --for=create ${join(" ", [for namespace in local.application_namespaces : "namespace/${namespace}"])} --timeout=${var.application_namespace_wait_timeout}"

    environment = {
      KUBECONFIG = var.kubeconfig_path
    }
  }

  depends_on = [kubectl_manifest.argocd_bootstrap_applications]
}

resource "kubernetes_secret_v1" "medusa" {
  metadata {
    name      = "medusa-secrets"
    namespace = "staging"
  }

  data = {
    COOKIE_SECRET                      = var.medusa_cookie_secret
    JWT_SECRET                         = var.medusa_jwt_secret
    NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY = var.medusa_publishable_key
    POSTGRES_PASSWORD                  = var.medusa_postgres_password
  }

  type = "Opaque"

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [terraform_data.application_namespaces_ready]
}

resource "kubernetes_secret_v1" "ghcr_pull" {
  metadata {
    name      = "ghcr-pull-secret"
    namespace = "staging"
  }

  data = {
    ".dockerconfigjson" = var.medusa_ghcr_dockerconfigjson
  }

  type = "kubernetes.io/dockerconfigjson"

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [terraform_data.application_namespaces_ready]
}

resource "kubernetes_secret_v1" "vaultwarden_admin" {
  metadata {
    name      = "admin-token-secret"
    namespace = "vaultwarden"
  }

  data = {
    key = var.vaultwarden_admin_token
  }

  type = "Opaque"

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [terraform_data.application_namespaces_ready]
}
