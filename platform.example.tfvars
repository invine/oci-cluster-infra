# Copy to platform.tfvars, populate with current values, and keep mode 0600.
tenancy_ocid     = ""
user_ocid        = ""
fingerprint      = ""
private_key_path = ""
region           = ""

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
