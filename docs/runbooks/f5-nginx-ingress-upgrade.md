# Prepare and execute the F5 NGINX Ingress Controller upgrade path

This runbook prepares the Terraform-managed F5 NGINX Ingress Controller Shared
Platform Service to move from controller `3.7.0` to `5.5.4`. Repository
preparation does not authorize a Terraform apply, Helm action, CRD apply or
patch, DNS change, Kubernetes mutation, or OCI Load Balancer mutation. Every
live hop requires a separately reviewed full Terraform plan and explicit human
authorization under the production upgrade runbook.

This is the F5 `nginx/nginx-ingress` controller, not the community
`ingress-nginx` controller. Use only the F5 artifacts linked here.

## Frozen sequence and identity contract

Run exactly one row per hop. Never skip, combine, or automatically substitute a
release.

| From chart/app | To chart/app | CRDs that must precede the Helm change |
| --- | --- | --- |
| `1.4.0` / `3.7.0` | `1.4.2` / `3.7.2` | Apply the [`v3.7.2` CRDs](https://raw.githubusercontent.com/nginx/kubernetes-ingress/v3.7.2/deploy/crds.yaml). |
| `1.4.2` / `3.7.2` | `2.0.1` / `4.0.1` | Complete the 3.x-to-4.x gate, then apply the [`v4.0.1` CRDs](https://raw.githubusercontent.com/nginx/kubernetes-ingress/v4.0.1/deploy/crds.yaml). |
| `2.0.1` / `4.0.1` | `2.6.4` / `5.5.4` | Complete the custom-template gate, then apply the [`v5.5.4` CRDs](https://raw.githubusercontent.com/nginx/kubernetes-ingress/v5.5.4/deploy/crds.yaml). |

The sequence is exactly `1.4.0/3.7.0 -> 1.4.2/3.7.2 -> 2.0.1/4.0.1 ->
2.6.4/5.5.4`. `platform/variables.tf` rejects any other chart version, and each
upstream chart's `appVersion` supplies the matching controller image tag.

Helm does not upgrade CRDs installed from a chart's `crds/` directory. Download
the exact destination manifest, record its URL and SHA-256 digest, review it,
and apply that reviewed file before changing `nginx_ingress_version`. Never use
CRDs from `main`, `latest`, a different tag, or a different controller.

Chart `1.4.0` renders the following live identities, which Terraform pins for
every stage:

- Helm release `nginx-ingress` in namespace `nginx-ingress`.
- Service and DaemonSet `nginx-ingress-controller`.
- Controller name `controller`.
- Service, DaemonSet, and pod selectors
  `app.kubernetes.io/name=nginx-ingress` and
  `app.kubernetes.io/instance=nginx-ingress`.

Before the first hop, record the Service UID, ClusterIP, IP families, ports and
NodePorts, annotations (including any OCI Load Balancer identifier), external
IP/hostname, traffic policy, selectors, and matching EndpointSlices. Resolve
and record the OCI Load Balancer OCID, addresses, listeners, backend sets, and
backend health. Every exit gate compares against this baseline. A Service
replacement, identity or address change, or unexplained backend change fails.

## Common preflight before every hop

Record the source and destination pair, Kubernetes version, Git revision,
operator, approver, and evidence timestamp. Then:

1. Read the destination release notes and the official [F5 upgrade
   procedure](https://docs.nginx.com/nginx-ingress-controller/install/upgrade/).
   Confirm the source is the immediately preceding row and the destination
   supports the current Kubernetes version.
2. Capture `helm list -n nginx-ingress`, `helm get values nginx-ingress -n
   nginx-ingress`, the controller image, DaemonSet state, recent events and
   error logs, and the complete identity baseline above.
3. List every `Ingress`, `IngressClass`, `VirtualServer`,
   `VirtualServerRoute`, `GlobalConfiguration`, `Policy`, and `TransportServer`.
   Record API versions, classes, hosts/listeners, status, and owning source.
   Unexplained or unhealthy resources stop the hop.
4. Establish the complete exit gate below before making a change. Record HTTP
   and TLS results for every endpoint in the endpoint contract.
5. Download and review the exact destination CRD manifest. Confirm its digest
   is the approved digest and use server-side dry-run against the live API. A
   rejection, destructive schema change, wrong tag, or conversion error stops.
6. Change only `nginx_ingress_version` to the next row in `platform.tfvars`.
   Generate a full saved platform plan through `scripts/terraform-local`; never
   use `-target`. The plan must update only `helm_release.nginx_ingress` to the
   next chart without replacing its namespace or Service identity. Any Explicit
   Secret change, unrelated drift, resource replacement, DNS action, or Load
   Balancer replacement stops the hop.
7. Record the plan checksum and obtain explicit human authorization for the
   exact CRD manifest and plan. Changed evidence, manifest, or plan invalidates
   approval.

After authorization, apply the reviewed destination CRDs first and wait until
every F5 CRD is `Established`. Only then apply the reviewed full Terraform plan.
Do not run Helm directly: Terraform remains the lifecycle owner.

## 3.x-to-4.x conversion gate

Complete this after `1.4.2/3.7.2` is healthy and before applying the `v4.0.1`
CRDs or changing the release to `2.0.1/4.0.1`.

1. Query all live `GlobalConfiguration`, `Policy`, and `TransportServer`
   objects across all namespaces. If any uses `k8s.nginx.org/v1alpha1`, stop.
   Update its authoritative manifest to `k8s.nginx.org/v1`, review the schema,
   and obtain separate authorization to reconcile it. F5 warns that leftover
   `v1alpha1` objects can be deleted during this migration.
2. Confirm both authoritative repositories and Live State contain no remaining
   `v1alpha1` object. Inspect `status.storedVersions` on
   `transportservers.k8s.nginx.org` and
   `globalconfigurations.k8s.nginx.org`. If either stores `v1alpha1`, use the
   exact status-patch procedure in the official guide only after separate
   approval; that patch is a live CRD mutation.
3. Confirm no numeric log-level override remains in Helm values, controller
   arguments, or a separately managed manifest. Terraform renders
   `controller.logLevel: info` and `controller.logFormat: glog` for chart 2.x;
   chart 1.x retains its numeric level until this hop.
4. Render chart `2.0.1` with the reviewed Terraform values. It must retain the
   Service and DaemonSet name, controller name, and both selector labels above.
   Diff the rendered Service against Live State and reject any immutable field,
   port, selector, annotation, or Load Balancer identity change.

Absence of those custom resources is evidence to record, not permission to skip
the query.

## 5.5 custom-template gate

Before the `2.6.4/5.5.4` hop, inspect the controller ConfigMap and Helm values
for custom `main-template`, `ingress-template`, `virtualserver-template`, or
`transportserver-template` entries. Controller 5.5 moves default-server
generation from `main-template` to `ingress-template`. If a custom template
exists, stop and follow F5's template-diff and migration procedure against the
exact source and destination tags before approving the hop. Record confirmed
absence when none exists.

## Observable exit gate after every hop

Do not advance until all checks pass simultaneously:

- **Release and CRDs:** `helm list` reports the exact destination pair and a
  deployed release. Every F5 CRD is `Established`, exposes the expected
  served/storage versions, and has no conversion or webhook error.
- **Controller DaemonSet:** `nginx-ingress-controller` has equal desired,
  current, ready, available, and updated counts, with one ready controller on
  every intended node. Its image is the destination application version. Events
  and logs contain no crash, reload, configuration, leader-election, conversion,
  or reconciliation failure.
- **Service identity:** `nginx-ingress-controller` has the baseline UID,
  ClusterIP, IP families, ports and NodePorts, annotations, traffic policy,
  selector labels, and OCI Load Balancer identifier. It was updated in place.
- **Load Balancer and backends:** the external IP/hostname, OCI Load Balancer
  OCID, and addresses equal the baseline. Listeners and backend sets are
  unchanged, expected controller backends are healthy, and EndpointSlices
  contain only ready controller pod endpoints on intended nodes.
- **Routing resources:** every declared Ingress and F5 custom resource remains
  valid with its expected address. No `GlobalConfiguration`, `Policy`, or
  `TransportServer` disappeared, regressed, or uses an incompatible API.
- **Declared HTTP/TLS endpoints:** verify HTTP behavior, certificate hostname
  and chain, and the expected authenticated or public response for each of
  `argocd.<duckdns-subdomain>.duckdns.org`, `echo.everk8s.duckdns.org`,
  `vaultwarden.everk8s.duckdns.org`, `medusa-staging.everk8s.duckdns.org`, and
  `medusa-api-staging.everk8s.duckdns.org`. Resolve the Argo CD hostname from
  reviewed `platform.tfvars`; never record credentials. A DNS, TLS, redirect,
  routing, websocket (where used), or representative request failure stops.

Record commands, outputs, timestamps, OCI console or CLI evidence, endpoint
expectations, and results. A pod list or successful TCP connection alone does
not pass this gate.

## Stop and recovery behavior

On any failed preflight, CRD dry-run/apply, rollout, identity comparison,
backend check, or endpoint check, stop before changing the version again.
Preserve Live State and evidence, follow the destination release's supported
forward-recovery guidance, rerun the complete gate, and reacquire invalidated
approval. Do not assume that changing the chart version backward is supported.

Never delete or recreate the Service to repair an upgrade. Never edit DNS or
the Generated OCI Load Balancer as part of this procedure. Any proposal that
needs a Service, DNS, ingress resource, CRD, or Load Balancer mutation beyond
the separately authorized matching CRD lifecycle returns to plan review.
