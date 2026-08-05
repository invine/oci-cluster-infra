# Decide Shared Platform Service upgrade pins and order

Type: grilling
Status: resolved
Blocked by: 02, 03, 04, 09

## Question

Which exact release patches, chart versions, CRD procedures, per-hop validations, and service order should the plan require to move Longhorn, Velero, cert-manager, F5 NGINX Ingress Controller, and Argo CD to the minimum safe set for Kubernetes `v1.36.1`?

## Answer

Freeze the Shared Platform Service pins listed below on August 5, 2026. Do not automatically substitute a newer patch during implementation; any substitution requires compatibility revalidation. The pins were verified against the official [Longhorn](https://charts.longhorn.io), [Velero](https://vmware-tanzu.github.io/helm-charts), [cert-manager](https://charts.jetstack.io), [F5 NGINX Ingress](https://helm.nginx.com/stable), and [Argo](https://argoproj.github.io/argo-helm) Helm repositories.

Complete all hops for one service, validating each hop separately, before starting the next service. Perform the entire sequence while the control plane remains on Kubernetes `v1.34.2`:

1. Longhorn
2. Velero
3. cert-manager
4. F5 NGINX Ingress Controller
5. Argo CD

Never combine multiple listed minor-version hops into one Terraform apply.

### Longhorn

Upgrade the chart and application together:

`1.7.2 → 1.8.2 → 1.9.2 → 1.10.2 → 1.11.3 → 1.12.0`

For every hop, run the release's official pre-upgrade checks, use that exact Helm chart's CRD lifecycle, and wait for all Longhorn managers, CSI components, and supporting DaemonSets/Deployments to become ready. Require every Longhorn node, volume, engine, and replica to be healthy with no rebuild pending before continuing. Do not enable the V2 engine or perform unrelated storage migration.

### Velero

Use these chart, application, and AWS plugin pins:

| Hop | Helm chart | Velero app | AWS plugin |
| --- | --- | --- | --- |
| Current | `7.2.2` | `1.14.1` | `1.8.2` |
| 1 | `8.7.2` | `1.15.2` | `1.11.1` |
| 2 | `10.1.3` | `1.16.2` | `1.12.2` |
| 3 | `11.4.0` | `1.17.1` | `1.13.2` |
| 4 | `12.1.0` | `1.18.1` | `1.14.2` |

Before each Helm hop, apply the CRDs generated for that exact Velero minor because the repository intentionally has `upgradeCRDs: false`. Update the server, node-agent, restore-helper image, and AWS plugin as one hop. Then require the Deployment and node-agent DaemonSet ready, the Backup Storage Location available, all Kopia BackupRepositories ready, and fresh `Completed` backups with zero errors or warnings for `staging`, `vaultwarden`, and `openvpn`. No restore rehearsal is required by the separately resolved backup decision.

### cert-manager

Upgrade one minor at a time:

`v1.16.1 → v1.17.4 → v1.18.6 → v1.19.6 → v1.20.3 → v1.21.1`

Before the first hop, replace the legacy `installCRDs = true` value with `crds.enabled = true` and confirm Helm owns the installed CRDs. Upgrade CRDs with each chart hop. Require controller, cainjector, webhook, and startup API check readiness; require the ClusterIssuer and every Certificate to remain Ready; verify existing HTTP/TLS endpoints before continuing.

### F5 NGINX Ingress Controller

Use these chart/application hops:

`1.4.0/3.7.0 → 1.4.2/3.7.2 → 2.0.1/4.0.1 → 2.6.4/5.5.4`

Apply the matching F5 CRDs before each major-version hop. Follow the 3.x-to-4.x migration values, preserving the existing Service name, controller name, and selector labels so the OCI Load Balancer is not replaced. Confirm no incompatible live `GlobalConfiguration`, `Policy`, or `TransportServer` objects exist. After every hop, require the controller DaemonSet ready, the Service identity and OCI Load Balancer addresses unchanged, healthy backends, and successful HTTP and TLS checks for every ingress host.

### Argo CD

Use these chart/application hops:

`7.6.12/2.12.6 → 7.7.23/2.13.4 → 7.9.1/2.14.11 → 8.2.7/3.0.12 → 9.0.6/3.1.9 → 9.3.7/3.2.6 → 9.5.11/3.3.9 → 10.2.2/3.4.6 → 10.2.3/3.5.0`

Review and satisfy every intervening Argo CD upgrade note. Upgrade the complete Helm release and its matching CRD set at each hop rather than changing only container images. Preserve the Terraform-owned Bootstrap Seed and repository registration. Require every Argo CD component ready, API/UI access working, repositories connected, and every Application `Healthy` and `Synced` before proceeding.

### Universal stop rule

Generate and review a Terraform plan for one hop at a time. A plan that replaces a protected resource, mutates Explicit Secret data, replaces the ingress Load Balancer, or contains unrelated changes must not be applied. Any failed CRD conversion, rollout, readiness, storage, backup, certificate, ingress, repository, or Application gate stops the sequence before the next hop. Do not assume that any component supports downgrade; recovery behavior remains component-specific.
