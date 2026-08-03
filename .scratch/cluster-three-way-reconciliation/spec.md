# Cluster three-way reconciliation

## Objective

Reconcile the production cluster across three independent evidence sets and assign every durable resource to exactly one lifecycle owner:

1. **Live State**: Kubernetes resources, Helm releases, Argo CD Applications, CRDs, storage, RBAC, ingress, and relevant OCI infrastructure.
2. **Terraform ownership**: configuration together with the authoritative Infrastructure State or Platform State.
3. **Argo ownership**: the Bootstrap Seed and every resource reachable through its child Applications.

Live State is evidence, not desired state. A resource is not Terraform-managed merely because configuration exists, and it is not Argo-managed merely because an unreachable manifest exists in Git.

## Agreed ownership model

- Terraform owns OCI Infrastructure and Shared Platform Services.
- Terraform owns the Bootstrap Seed and all Explicit Secrets.
- Argo CD owns Application Workloads and all Application Namespaces.
- The External Backup Store is an intentionally external prerequisite and outlives the cluster compartment.
- Only the Bootstrap Seed syncs automatically. Child Applications require manual sync.
- Generated Resources follow their managed parent and do not receive a second IaC owner.
- Every Ownership Gap receives an explicit Disposition before live cutover.

## Desired bootstrap sequence

1. Provision the External Backup Store outside the cluster compartment and supply its name and Object Storage namespace.
2. Apply the `infra` Terraform root to create the OCI network, OKE cluster, node pool, and kubeconfig.
3. Apply the `platform` Terraform root to install Shared Platform Services, including Argo CD through Helm.
4. Terraform creates the global `k8s-charts` Repository Registration and the Bootstrap Seed.
5. The Bootstrap Seed automatically creates and tracks Application Namespaces, the Workload Project, the downstream Medusa Repository Registration, and child Applications.
6. Terraform waits for Application Namespaces to exist and then creates Explicit Secrets.
7. Child Applications remain unsynced until a human reviews and manually syncs them.

## Authoritative Terraform states

| State | Current location | Desired location | Contents |
| --- | --- | --- | --- |
| Infrastructure State | `terraform.tfstate` | unchanged | OCI networking, OKE, node pools, kubeconfig, and supporting resources |
| Platform State | `applications/terraform.tfstate` | `platform/terraform.tfstate` | Helm releases, platform namespaces, bootstrap resources, and Explicit Secrets |

The two states remain separate. `.terraform/terraform.tfstate` files are backend metadata, not authoritative resource state.

## Reconciliation dispositions

| Resource class or live object | Evidence | Desired owner | Disposition |
| --- | --- | --- | --- |
| OCI compartment, VCN, gateways, routes, subnets, security lists, OKE cluster, node pool | Live OCI plus Infrastructure State | Terraform | Preserve |
| OCI Object Storage bucket `k8s-velero-backup` | Live OCI; referenced by Velero | Intentionally external | Preserve as the External Backup Store outside the cluster compartment and both Terraform states |
| OKE-created compute instances, VNICs, boot volumes, and related node resources | Live OCI with Terraform-managed node-pool parent | Generated Resource | Follow the node-pool lifecycle |
| OCI Load Balancer created for `nginx-ingress-controller` | Live OCI with Kubernetes Service parent | Generated Resource | Follow the Terraform-managed NGINX Helm release and its Service |
| Velero OCI customer secret key | Live OCI plus Platform State | Terraform | Preserve; it supplies the generated Velero cloud-credentials Secret |
| Argo CD, cert-manager, Longhorn, NGINX Ingress, and Velero releases | Live Helm plus Platform State | Terraform | Preserve as Shared Platform Services |
| `argocd`, `cert-manager`, `longhorn-system`, `nginx-ingress`, and `velero` namespaces | Live Kubernetes plus Platform State | Terraform | Preserve as platform namespaces |
| Argo CD, cert-manager, Longhorn, NGINX Ingress, and Velero CRDs and RBAC | Live Kubernetes with Helm ownership metadata | Generated Resource | Follow the corresponding Terraform-managed Helm release |
| `argocd-bootstrap` Application | Live Argo CD plus Platform State | Terraform | Preserve as Bootstrap Seed |
| `echo`, `openvpn`, `staging`, and `vaultwarden` namespaces | Live Kubernetes; absent from both IaC owners | Argo CD | Adopt in place through explicit Namespace manifests |
| `echo-app`, `openvpn`, `medusa-staging`, and `vaultwarden` child Applications | Live Argo CD plus reachable manifests | Argo CD | Preserve with manual sync policy |
| Child workload Deployments, StatefulSets, Services, Ingresses, PVCs, ConfigMaps, and Velero Schedules | Live Argo resource trees | Argo CD | Preserve; protect durable resources from unconfirmed deletion |
| Child workload ServiceAccounts, Roles, and RoleBindings, when rendered | Reachable child Application manifests | Argo CD | Keep namespaced and constrained by the Workload Project |
| Dynamically provisioned PVs and Longhorn volume resources | Live storage graph | Generated Resource | Follow their Argo-managed PVC and Terraform-managed Longhorn parents |
| `staging/medusa-secrets` | Live Kubernetes only | Terraform | Secret Adoption with no value change |
| `staging/ghcr-pull-secret` | Live Kubernetes only | Terraform | Secret Adoption with no value change |
| `vaultwarden/admin-token-secret` | Live Kubernetes only | Terraform | Secret Adoption with no value change |
| `velero/velero-repo-credentials` | Live Kubernetes plus Platform State | Terraform | Preserve; move its value out of configuration defaults |
| `argocd/k8s-charts-repo` | Live Kubernetes plus Platform State | Terraform | Preserve as global bootstrap Repository Registration |
| `argocd/repo-1559886016` | Live Kubernetes only | Argo CD | Adopt in place as the Medusa Repository Registration |
| Helm/controller credentials, webhook certificates, ACME accounts, and ingress TLS Secrets | Live Kubernetes with managed parents | Generated Resource | Preserve through their parent lifecycle |
| Kubernetes system namespaces, system RBAC, and OKE control-plane resources | Live Kubernetes with OKE parent | Generated Resource | Preserve |
| Live `argocd-cm` | Helm release metadata; stale unreachable Git snapshot | Terraform through Helm | Remove stale Git snapshot; configure only through Helm values |
| Generated `default` AppProject | Argo CD default | Generated Resource | Reserve for Bootstrap Seed only |
| `application-workloads` AppProject | Missing | Argo CD | Create with exact repositories, Application Namespaces, the shared `velero` destination for Workload Backup Schedules, and no cluster-scoped kinds |
| Unreachable bootstrap repository and project snapshots | Git only | None | Remove after desired root graph replaces them |
| DuckDNS record | External service updated by the Terraform provisioner | Intentionally external | Preserve current update mechanism; no second IaC owner |

## Explicit Secret contracts

Only names and key contracts are recorded here. Values must never be written to this repository.

| Secret | Type | Required keys |
| --- | --- | --- |
| `staging/medusa-secrets` | `Opaque` | `COOKIE_SECRET`, `JWT_SECRET`, `NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY`, `POSTGRES_PASSWORD` |
| `staging/ghcr-pull-secret` | `kubernetes.io/dockerconfigjson` | `.dockerconfigjson` |
| `vaultwarden/admin-token-secret` | `Opaque` | `key` |
| `velero/velero-repo-credentials` | `Opaque` | `repository-password` |

Terraform sensitive variables are the Secret Value Authority. Argo manifests reference these Secrets by name and never contain their values.

## Local sensitive-artifact contract

- Real tfvars, state files, state backups, saved plans, and kubeconfigs are excluded from Git.
- Local Sensitive Artifacts use mode `0600` and Terraform runs under `umask 077`.
- Tracked example tfvars contain names and placeholders only.
- Local state is accepted for this refactor; migration to a private, versioned OCI Object Storage backend is deferred.
- Disk encryption is outside the accepted scope.

## Secret lifecycle

- Initial Secret Adoption preserves exact live names and values.
- The first import plan must show no Secret data change.
- Secret Rotation is a separate deliberate operation after adoption.
- After Terraform updates an environment-backed Secret, a human restarts only affected Pods and verifies the application.
- Terraform never mutates an Argo-managed workload to force a restart.

## Non-goals

- Do not run `terraform apply` or `terraform import` in this implementation task.
- Do not delete or recreate live resources.
- Do not sync child Applications.
- Do not rotate Secret values.
- Do not create, import, modify, or destroy the External Backup Store.
- Do not migrate state to Object Storage yet.

## Acceptance criteria

- The Terraform root is named `platform`, while Infrastructure State and Platform State remain separate.
- Terraform configuration installs Argo CD and creates the Bootstrap Seed before waiting for Argo-created Application Namespaces.
- The reachable root bootstrap graph contains only desired Argo-owned resources.
- Child Applications remain manual and use the restricted Workload Project.
- All Explicit Secrets have Terraform resources and sensitive variables without defaults.
- The existing private Velero Object Storage bucket is documented as an External Backup Store and has no Terraform resource or state ownership.
- Sensitive local artifacts are ignored and documented.
- Terraform formatting and validation pass without contacting or changing the cluster.
- Helm/Kubernetes manifests render and validate locally.
- A human-only cutover ticket contains the exact safe migration order.

## Implementation validation

Completed locally on 2026-08-02 without `terraform plan`, `terraform apply`, `terraform import`, Argo sync, or live deletion:

- `terraform validate` passed for both `infra` and `platform`.
- `terraform fmt -check` passed for the `platform` root and tracked example tfvars.
- The Platform State remained readable with all original resource addresses after the directory rename.
- Helm lint passed for Echo, OpenVPN, Vaultwarden, and Medusa.
- All four child Applications parse as manual and use `application-workloads`.
- The bootstrap graph contains the four expected Application Namespaces, the Workload Project, and `repo-1559886016`.
- Rendered child charts contain only namespaced workload resources and no Explicit Secret manifests.
- All rendered durable PVCs contain Argo CD prune/delete confirmation safeguards.
- Sensitive local artifacts are ignored and have mode `0600`.
