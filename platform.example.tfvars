# Copy to platform.tfvars, populate with current values, and keep mode 0600.
tenancy_ocid     = ""
user_ocid        = ""
fingerprint      = ""
private_key_path = ""
region           = ""

# cert-manager advances one reviewed Terraform apply at a time. Do not skip or
# substitute stages: v1.16.1 -> v1.17.4 -> v1.18.6 -> v1.19.6 -> v1.20.3 -> v1.21.1.
cert_manager_version = "v1.16.1"

# Longhorn advances one reviewed Terraform apply at a time. Do not skip or
# substitute stages: 1.7.2 -> 1.8.2 -> 1.9.2 -> 1.10.2 -> 1.11.3 -> 1.12.0.
longhorn_version = "1.7.2"

lets_encrypt_email         = ""
lets_encrypt_issuer_name   = "letsencrypt-prod"
lets_encrypt_issuer_server = "https://acme-v02.api.letsencrypt.org/directory"
# Pre-existing private External Backup Store; Terraform does not own its lifecycle.
velero_backup_bucket_namespace = ""
duckdns_subdomain              = ""
duckdns_token                  = ""

# Explicit Secrets: preserve the exact live values during initial adoption.
velero_repository_password   = ""
medusa_postgres_password     = ""
medusa_jwt_secret            = ""
medusa_cookie_secret         = ""
medusa_publishable_key       = ""
medusa_ghcr_dockerconfigjson = ""
vaultwarden_admin_token      = ""
