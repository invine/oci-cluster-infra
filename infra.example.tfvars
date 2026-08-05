# Copy to infra.tfvars, populate locally, and keep mode 0600.
tenancy_ocid     = ""
user_ocid        = ""
fingerprint      = ""
private_key_path = ""
region           = ""

par_url                      = ""
kubernetes_public_ip_enables = false
duckdns_subdomain            = ""
duckdns_token                = ""

# Repository-preparation baseline: keep only the current v1.34.2 worker pool.
# Replace the placeholder with the exact approved regional OKE image OCID locally.
control_plane_kubernetes_version = "v1.34.2"
worker_pools = {
  "v1.34.2" = {
    name               = "prod-cluster-pool-v134-8cde4f63"
    kubernetes_version = "v1.34.2"
    size               = 3
    image_ocid         = "ocid1.image.oc1.<region>.<approved-image-ocid>"
  }
}
