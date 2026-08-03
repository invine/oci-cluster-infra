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
  description = "Argo CD Helm chart version."
  type        = string
  default     = "7.6.12"
}

variable "cert_manager_version" {
  description = "cert-manager Helm chart version."
  type        = string
  default     = "v1.16.1"
}

variable "longhorn_version" {
  description = "Longhorn Helm chart version."
  type        = string
  default     = "1.7.2"
}

variable "nginx_ingress_version" {
  description = "NGINX Ingress Controller Helm chart version."
  type        = string
  default     = "1.4.0"
}

variable "velero_version" {
  description = "Velero Helm chart version."
  type        = string
  default     = "7.2.2"
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

variable "velero_aws_plugin_image" {
  default = "docker.io/velero/velero-plugin-for-aws:v1.8.2"
}

variable "velero_restore_helper_image" {
  default = "docker.io/velero/velero-restore-helper:v1.14.1"
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
