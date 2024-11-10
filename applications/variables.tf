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
  default = "../prod-cluster_kubeconfig"
}

variable "argocd_bootstrap_repo_name" {
  default = "k8s-charts-repo"
}

variable "argocd_bootstrap_repo_url" {
  default = "https://github.com/invine/k8s-charts"
}

variable "argocd_bootstrap_repo_app_path" {
  default = "argocd-bootstrap/applications"
}

variable "argocd_bootstrap_repo_prj_path" {
  default = "argocd-bootstrap/projects"
}

variable "argocd_bootstrap_repo_branch" {
  default = "main"
}

variable "argocd_version" {
  default = "7.6.11"
}

variable "lets_encrypt_issuer_name" {
  default = "letsencrypt-staging"
}

variable "lets_encrypt_issuer_server" {
  default = "https://acme-staging-v02.api.letsencrypt.org/directory"
}

variable "lets_encrypt_email" {
  description = "Email for Let's Encrypt service"
}

variable "velero_backup_bucket_name" {
  default = "k8s-velero-backup"
}

variable "velero_backup_bucket_namespace" {
  description = "Oracle Cloud Tenancy"
}

variable "velero_backup_bucket_prefix" {
  description = "Prefix in backup bucket"
  default     = ""
}

variable "velero_aws_plugin_image" {
  default = "velero/velero-plugin-for-aws:v1.8.2"
}

variable "velero_repository_password" {
  default = "static-passw0rd"
}

variable "duckdns_subdomain" {
  description = "DuckDNS Subdomain"
}

variable "duckdns_token" {
  description = "DuckDNS Token"
}
