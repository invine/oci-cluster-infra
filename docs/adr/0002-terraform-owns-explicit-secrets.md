# Terraform owns explicit Kubernetes secrets

Sensitive Terraform variables are the Secret Value Authority, Terraform owns each Explicit Secret even inside an Argo-owned Application Namespace, and Argo manifests reference Secrets only by name. We chose this over OCI Vault plus External Secrets because the cluster must remain Basic/free and the simpler operational model is preferred; local Terraform state and tfvars are therefore sensitive artifacts protected by Git exclusion and mode `0600`, and Secret Rotation requires a manual workload restart.
