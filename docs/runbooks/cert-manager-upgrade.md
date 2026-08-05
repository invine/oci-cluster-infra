# Prepare and execute the cert-manager upgrade path

This runbook prepares the Terraform-managed cert-manager Shared Platform
Service to move from `v1.16.1` to `v1.21.1`. Repository preparation does not
authorize a Terraform apply, Helm action, CRD change, Certificate change, or
other mutation of Live State. Each live hop requires a separately reviewed full
Terraform plan and explicit human authorization under the production upgrade
runbook.

## Frozen sequence and CRD contract

Use exactly one row per hop. Never skip, combine, or automatically substitute a
release.

| From | To chart/app | Required destination review | CRD lifecycle |
| --- | --- | --- | --- |
| `v1.16.1` | `v1.17.4` / `v1.17.4` | Read the 1.17 upgrade and release notes. Check compatibility with the stronger hashes used when large RSA keys rotate, remove any explicit `ValidateCAA` feature gate, and account for structured log changes. | The `v1.17.4` chart templates and upgrades all six CRDs as part of the Helm release. |
| `v1.17.4` | `v1.18.6` / `v1.18.6` | Read the 1.18 upgrade and release notes. Account for the new `Always` private-key rotation default, the `revisionHistoryLimit` default of one, and resulting cleanup of stale CertificateRequests. | The `v1.18.6` chart templates and upgrades all six CRDs as part of the Helm release. |
| `v1.18.6` | `v1.19.6` / `v1.19.6` | Read the 1.19 upgrade and release notes. Confirm no tooling creates Orders or Challenges directly and account for the ACME metric-label and aggregate-RBAC changes. | The `v1.19.6` chart templates and upgrades all six CRDs as part of the Helm release. |
| `v1.19.6` | `v1.20.3` / `v1.20.3` | Read the 1.20 upgrade and release notes. Reconfirm that no tooling depends on the removed Order or Challenge permissions in the `cert-manager-edit` aggregate role. | The `v1.20.3` chart templates and upgrades all six CRDs as part of the Helm release. |
| `v1.20.3` | `v1.21.1` / `v1.21.1` | Read the 1.21 upgrade and release notes and satisfy every documented breaking-change precondition. | The `v1.21.1` chart templates and upgrades all six CRDs as part of the Helm release. |

Terraform fixes this sequence in `platform/variables.tf` and enables
`crds.enabled` on the existing release. cert-manager places CRDs in its normal
chart templates rather than Helm's install-only `crds/` directory, so a Helm
upgrade updates the matching CRDs in the same release transaction. Do not apply
CRDs from another tag or add a second CRD manager. Keep the chart's default
`crds.keep: true`; uninstalling cert-manager is outside this runbook.

Review the official notes immediately before every live hop:

- [cert-manager upgrade procedure](https://cert-manager.io/docs/installation/upgrade/)
- [`1.16` to `1.17`](https://cert-manager.io/docs/releases/upgrading/upgrading-1.16-1.17/) and [1.17 release notes](https://cert-manager.io/docs/releases/release-notes/release-notes-1.17/)
- [`1.17` to `1.18`](https://cert-manager.io/docs/releases/upgrading/upgrading-1.17-1.18/) and [1.18 release notes](https://cert-manager.io/docs/releases/release-notes/release-notes-1.18/)
- [`1.18` to `1.19`](https://cert-manager.io/docs/releases/upgrading/upgrading-1.18-1.19/) and [1.19 release notes](https://cert-manager.io/docs/releases/release-notes/release-notes-1.19/)
- [`1.19` to `1.20`](https://cert-manager.io/docs/releases/upgrading/upgrading-1.19-1.20/) and [1.20 release notes](https://cert-manager.io/docs/releases/release-notes/release-notes-1.20/)
- [`1.20` to `1.21`](https://cert-manager.io/docs/releases/upgrading/upgrading-1.20-1.21/) and [1.21 release notes](https://cert-manager.io/docs/releases/release-notes/release-notes-1.21/)

## One-time Helm ownership gate

Complete this gate before planning the first live hop. It proves that enabling
the current value spelling preserves the existing Helm ownership model; it does
not authorize patching labels or annotations.

The required CRDs are:

```text
certificates.cert-manager.io
certificaterequests.cert-manager.io
issuers.cert-manager.io
clusterissuers.cert-manager.io
orders.acme.cert-manager.io
challenges.acme.cert-manager.io
```

For every name, record these read-only fields:

```sh
kubectl get crd <name> \
  -o jsonpath='{.metadata.labels.app\.kubernetes\.io/managed-by}{"\t"}{.metadata.annotations.meta\.helm\.sh/release-name}{"\t"}{.metadata.annotations.meta\.helm\.sh/release-namespace}{"\n"}'
```

Every line must be exactly `Helm`, `cert-manager`, and `cert-manager`, in that
order. Also require all six CRDs to report `Established=True`, and use
`helm get manifest cert-manager -n cert-manager` to confirm that the installed
release manifest contains the same six CRD names. Record `helm status` and
`helm get values --all`; the release must be deployed at `v1.16.1` with CRD
installation enabled.

If any CRD is absent, has different ownership metadata, is not Established, or
is missing from the Helm manifest, stop. Ownership adoption or repair is a
separate Live State mutation requiring its own diagnosis, reviewed procedure,
backup, and explicit authorization. Do not begin a version hop and do not patch
metadata as an incidental runbook step.

## Baseline before every hop

Record the source and destination rows, current Kubernetes version, Git
revision, operator, approver, and evidence timestamp. Then:

1. Read the exact destination upgrade and release notes and complete their
   preconditions. Back up all cert-manager resources using the official backup
   procedure; record the artifact without committing sensitive material.
2. Re-run the ownership checks above. Require the Helm release and all six CRDs
   to match the source row, and require every CRD to be Established with no
   conversion or reconciliation errors.
3. Pass the complete observable exit gate below at the source version. Record
   the ClusterIssuer and Certificate condition messages, certificate expiry
   times, referenced TLS Secret names, and the endpoint inventory.
4. Change only `cert_manager_version` to the next row in `platform.tfvars`.
   Generate a full, saved platform plan through `scripts/terraform-local`;
   never use `-target`. The plan must update only
   `helm_release.cert_manager` to the exact next chart and its matching CRDs.
5. Reject a plan that removes or replaces a CRD, Certificate, ClusterIssuer,
   Explicit Secret, ingress, or release; changes Explicit Secret data; or
   contains unrelated drift. Record the plan checksum and obtain explicit
   human authorization for that exact plan. Any regenerated plan or stale or
   failed health evidence invalidates approval.

The authorized full Terraform apply performs one Helm chart and matching CRD
hop. Do not run a separate Helm upgrade or CRD apply. A failed Helm release,
CRD update, conversion, startup API check, or webhook rollout stops the hop.

## Observable exit gate after every hop

Run the entire gate after the authorized apply, including after the first hop.
Do not advance until every item passes simultaneously.

- **Release and CRDs:** `helm status cert-manager -n cert-manager` reports a
  deployed release at the exact destination chart/app pair. The six CRDs retain
  the ownership metadata above, are Established, and their schemas match the
  destination release. Kubernetes events and cert-manager logs contain no CRD
  conversion, storage-version, or reconciliation failure.
- **Controller:** `kubectl rollout status deployment/cert-manager -n
  cert-manager` succeeds. Desired, updated, ready, and available replicas match;
  pods use the destination image and show no issuance or reconciliation error.
- **cainjector:** `kubectl rollout status deployment/cert-manager-cainjector -n
  cert-manager` succeeds. Desired, updated, ready, and available replicas match,
  and logs contain no CA bundle injection failure.
- **Webhook:** `kubectl rollout status deployment/cert-manager-webhook -n
  cert-manager` succeeds. Its Service has ready endpoints; the validating and
  mutating webhook configurations retain nonempty CA bundles; logs and events
  contain no TLS, admission, or conversion failure.
- **Startup API check:** the destination
  `cert-manager-startupapicheck` Job completes successfully. Record the Job
  status and logs. Then run `cmctl check api --wait=2m`; it must report that the
  cert-manager API is ready. If the Helm hook Job was removed after completion,
  the Helm output plus `cmctl` result must both be recorded rather than treating
  an absent Job as success.
- **ClusterIssuer:** `kubectl wait --for=condition=Ready clusterissuer --all
  --timeout=2m` succeeds. The Terraform-managed ClusterIssuer has `Ready=True`,
  its observed generation matches its generation, and its ACME account Secret
  remains present without value rotation.
- **Certificates:** `kubectl wait --for=condition=Ready certificate --all
  --all-namespaces --timeout=5m` succeeds. The pre-hop and post-hop Certificate
  inventories are identical unless a separately expected Generated Resource
  change is documented. Every Certificate has `Ready=True`, a current target
  Secret, a valid future expiry, and no unexpected reissuance, failed
  CertificateRequest, Order, or Challenge.
- **Existing HTTP/TLS endpoints:** use the pre-hop inventory of every declared
  ingress host and path. Repeat each HTTP request and each TLS request with the
  same expected status, redirect, and functional assertion recorded at
  baseline. TLS checks must use normal certificate and hostname verification;
  `curl -k` is prohibited. For each TLS host, record the served certificate
  subject/SAN, issuer, serial, and expiry and confirm they remain valid. The
  Terraform-declared `https://argocd.<duckdns_subdomain>.duckdns.org` endpoint
  is mandatory, and all Argo-managed ingress endpoints are equally required.

Useful read-only inventory commands are:

```sh
kubectl get ingress --all-namespaces
kubectl get clusterissuer
kubectl get certificate,certificaterequest,order.acme.cert-manager.io,challenge.acme.cert-manager.io --all-namespaces
kubectl get deployment,service,endpoints,job,pod -n cert-manager
kubectl get validatingwebhookconfiguration,mutatingwebhookconfiguration | grep cert-manager
```

Inventory commands do not replace the readiness and functional assertions.
Capture explicit results for every object and endpoint rather than accepting an
empty or partial command result.

## Stop and recovery behavior

Any failed ownership, CRD, plan, rollout, webhook, startup API, ClusterIssuer,
Certificate, issuance, or endpoint check stops progression before changing the
version again. Preserve Live State and evidence, diagnose the failed hop, use
the destination release's supported forward-repair guidance, rerun the complete
gate, and obtain fresh approval if evidence or the plan changed.

Do not uninstall cert-manager, delete or replace CRDs, rotate the Generated
Resource ACME account key or any Explicit Secret, force certificate renewal,
bypass admission, or assume changing `cert_manager_version` backward is a safe
rollback. Those are separate mutations outside this runbook and require their
own reviewed recovery procedure and explicit authorization.
