variable "region" {
  description = "OCI region"
  type        = string
  sensitive   = true
}

variable "tenancy_ocid" {
  description = "The OCID of your tenancy"
  type        = string
  sensitive   = true
}

variable "user_ocid" {
  description = "The OCID of your user"
  type        = string
  sensitive   = true
}

variable "fingerprint" {
  description = "The fingerprint of your API key"
  type        = string
  sensitive   = true
}

variable "private_key_path" {
  description = "Private Key value"
  type        = string
  sensitive   = true
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig for the Terraform-managed OKE cluster."
  type        = string
  default     = "../prod-cluster_kubeconfig"
}

variable "argocd_bootstrap_repo_name" {
  description = "Name of the Terraform-managed bootstrap repository registration."
  type        = string
  default     = "k8s-charts-repo"
}

variable "argocd_bootstrap_repo_url" {
  description = "Git repository containing the Argo CD bootstrap graph."
  type        = string
  default     = "https://github.com/invine/k8s-charts"
}

variable "argocd_bootstrap_repo_path" {
  description = "Recursive path containing the desired root Argo CD bootstrap graph."
  type        = string
  default     = "argocd-bootstrap/root"
}

variable "argocd_bootstrap_repo_branch" {
  description = "Git revision reconciled by the Bootstrap Seed."
  type        = string
  default     = "main"
}

variable "argocd_version" {
  description = "Exact Argo CD Helm chart version for the current frozen serial upgrade stage."
  type        = string
  default     = "10.2.3"

  validation {
    condition = contains([
      "7.6.12",
      "7.7.23",
      "7.9.1",
      "8.2.7",
      "9.0.6",
      "9.3.7",
      "9.5.11",
      "10.2.2",
      "10.2.3",
    ], var.argocd_version)
    error_message = "argocd_version must be a frozen serial upgrade stage from docs/runbooks/argocd-upgrade.md."
  }
}

variable "cert_manager_version" {
  description = "Exact cert-manager Helm chart version for the current frozen serial upgrade stage."
  type        = string
  default     = "v1.16.1"

  validation {
    condition = contains([
      "v1.16.1",
      "v1.17.4",
      "v1.18.6",
      "v1.19.6",
      "v1.20.3",
      "v1.21.1",
    ], var.cert_manager_version)
    error_message = "cert_manager_version must be a frozen serial upgrade stage from docs/runbooks/cert-manager-upgrade.md."
  }
}

variable "longhorn_version" {
  description = "Exact Longhorn Helm chart version for the current frozen serial upgrade stage."
  type        = string
  default     = "1.7.2"

  validation {
    condition = contains([
      "1.7.2",
      "1.8.2",
      "1.9.2",
      "1.10.2",
      "1.11.3",
      "1.12.0",
    ], var.longhorn_version)
    error_message = "longhorn_version must be a frozen serial upgrade stage from docs/runbooks/longhorn-upgrade.md."
  }
}

variable "nginx_ingress_version" {
  description = "Exact F5 NGINX Ingress Controller Helm chart version for the current frozen serial upgrade stage."
  type        = string
  default     = "1.4.0"

  validation {
    condition = contains([
      "1.4.0",
      "1.4.2",
      "2.0.1",
      "2.6.4",
    ], var.nginx_ingress_version)
    error_message = "nginx_ingress_version must be a frozen serial upgrade stage from docs/runbooks/f5-nginx-ingress-upgrade.md."
  }
}

variable "nginx_proxy_protocol_enabled" {
  description = "Enable OCI PROXY protocol v2 and matching F5 listeners together. One-way on an existing OCI LB: setting false is NOT rollback. See docs/runbooks/echo-client-identity.md."
  type        = bool
  default     = false
}

variable "nginx_lb_trusted_cidrs" {
  description = "Explicit OCI LB source subnet CIDRs trusted by F5 real-IP processing. Never use a public catch-all."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.nginx_lb_trusted_cidrs :
      can(cidrhost(cidr, 0)) && !can(regex("/0+$", cidr))
    ])
    error_message = "nginx_lb_trusted_cidrs must contain valid CIDRs with a nonzero prefix length."
  }
}

variable "velero_version" {
  description = "Exact Velero Helm chart version for the current frozen serial upgrade stage."
  type        = string
  default     = "7.2.2"

  validation {
    condition = contains([
      "7.2.2",
      "8.7.2",
      "10.1.3",
      "11.4.0",
      "12.1.0",
    ], var.velero_version)
    error_message = "velero_version must be a frozen serial upgrade stage from docs/runbooks/velero-upgrade.md."
  }
}

variable "application_namespace_wait_timeout" {
  description = "Maximum time Terraform waits for Argo CD to create Application Namespaces."
  type        = string
  default     = "5m"
}

variable "lets_encrypt_issuer_name" {
  default = "letsencrypt-staging"
}

variable "lets_encrypt_issuer_server" {
  default = "https://acme-staging-v02.api.letsencrypt.org/directory"
}

variable "lets_encrypt_email" {
  description = "Email for Let's Encrypt service"
  type        = string
}

variable "velero_backup_bucket_name" {
  description = "Name of the pre-existing External Backup Store. Terraform references but does not own this bucket."
  type        = string
  default     = "k8s-velero-backup"
}

variable "velero_backup_bucket_namespace" {
  description = "Object Storage namespace containing the pre-existing External Backup Store."
  type        = string
}

variable "velero_backup_bucket_prefix" {
  description = "Object prefix used by Velero inside the External Backup Store."
  type        = string
  default     = ""
}

variable "velero_restore_image_mappings" {
  description = "Image rewrite mappings for Velero ChangeImageNameAction during restore."
  type        = map(string)
  default = {
    restore_helper = "velero/velero-restore-helper,docker.io/velero/velero-restore-helper"
    openvpn        = "elswork/openvpn,docker.io/elswork/openvpn"
    vaultwarden    = "vaultwarden/server,docker.io/vaultwarden/server"
  }
}

variable "velero_repository_password" {
  description = "Current password for Velero file-system backup repositories."
  type        = string
  sensitive   = true
}

variable "duckdns_subdomain" {
  description = "DuckDNS Subdomain"
  type        = string
}

variable "duckdns_token" {
  description = "DuckDNS Token"
  type        = string
  sensitive   = true
}

variable "medusa_postgres_password" {
  description = "Current POSTGRES_PASSWORD value in staging/medusa-secrets."
  type        = string
  sensitive   = true
}

variable "medusa_jwt_secret" {
  description = "Current JWT_SECRET value in staging/medusa-secrets."
  type        = string
  sensitive   = true
}

variable "medusa_cookie_secret" {
  description = "Current COOKIE_SECRET value in staging/medusa-secrets."
  type        = string
  sensitive   = true
}

variable "medusa_publishable_key" {
  description = "Current NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY value in staging/medusa-secrets."
  type        = string
  sensitive   = true
}

variable "medusa_ghcr_dockerconfigjson" {
  description = "Current .dockerconfigjson value in staging/ghcr-pull-secret."
  type        = string
  sensitive   = true
}

variable "vaultwarden_admin_token" {
  description = "Current key value in vaultwarden/admin-token-secret."
  type        = string
  sensitive   = true
}
