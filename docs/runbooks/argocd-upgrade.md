# Prepare and execute the Argo CD upgrade path

This runbook prepares the Terraform-managed Argo CD Shared Platform Service to
move from chart/application `7.6.12/2.12.6` to `10.2.3/3.5.0`. Repository
preparation does not authorize a Terraform apply, Helm action, CRD change,
Application sync, repository change, Secret change, or any other mutation of
Live State. Each live hop requires a separately reviewed full Terraform plan
and explicit human authorization under the production upgrade runbook.

Complete this service after the prepared Longhorn, Velero, cert-manager, and F5
NGINX Ingress Controller sequences, and while Kubernetes remains `v1.34.2`.

## Frozen release and CRD sequence

Use exactly one row per hop. Never skip, combine, or automatically substitute a
chart or application release.

| From chart/app | To chart/app | Destination-specific preconditions |
| --- | --- | --- |
| `7.6.12` / `2.12.6` | `7.7.23` / `2.13.4` | Inventory users of bundled Helm, custom Flux actions/health, Dex, the manually-triggered CronJob name, downloaded-log filename assumptions, and Kustomize proxy settings. Update dependent automation or RBAC where the official notes require it. |
| `7.7.23` / `2.13.4` | `7.9.1` / `2.14.11` | Do not use the broken `2.14.0` manifests. Check consumers of the sanitized AppProject API response, bundled Helm `3.16.2`, and the destination's new health assessments; prove every Application remains Healthy. |
| `7.9.1` / `2.14.11` | `8.2.7` / `3.0.12` | Complete the full `2.14→3.0` audit below, including RBAC, repository storage, tracking, metrics, ApplicationSet selectors, Helm behavior, exclusions, and CR status behavior. Take an Argo CD disaster-recovery export before crossing the major boundary. |
| `8.2.7` / `3.0.12` | `9.0.6` / `3.1.9` | Check static-asset symlinks, users of the deprecated v1 resource-actions API, OIDC PKCE callback registration, bundled Helm/Kustomize behavior, and newly sanitized project API responses. |
| `9.0.6` / `3.1.9` | `9.3.7` / `3.2.6` | Source Hydrator paths must not target a repository root. Check `.argocd-source.yaml` Kustomize overrides, direct repo-server gRPC clients, CronJob health changes, and the ApplicationSet 5,000-resource status limit. |
| `9.3.7` / `3.2.6` | `9.5.11` / `3.3.9` | Confirm CRDs will be upgraded by Helm, as configured here; do not client-side apply the oversized ApplicationSet CRD. Audit Source Hydrator Git-notes/path behavior, anonymous Settings API clients, timeout settings, deprecated self-heal flags, and bundled Helm/Kustomize changes. |
| `9.5.11` / `3.3.9` | `10.2.2` / `3.4.6` | Audit ApplicationSet cluster generators, templates, selectors, and other consumers of Kubernetes version strings for the change from `Major.Minor` to `vMajor.Minor.Patch`. Review Applications whose resources have missing health, gRPC DNS service configuration, Dex preprocessing and `ContinueOnConnectorFailure` behavior, go-oidc key-rotation grace periods, and OpenTelemetry consumers. |
| `10.2.2` / `3.4.6` | `10.2.3` / `3.5.0` | Audit plain-HTTP OCI repositories and dependencies, `.spec.source.helm.version`, UI extensions, generated gRPC/OpenAPI event clients, GnuPG signature verification, and strict repo-server TLS flags. If impersonation is enabled, grant each destination service account the documented verbs for server operations. Move host keys for credential-less SSH repositories into `argocd-ssh-known-hosts-cm`. Apply the documented Helm 4 and client migrations wherever the audit finds use. |

The configured values explicitly keep `crds.install: true` and `crds.keep: true`.
All stages are newer than chart `5.2.0`, where argo-helm moved the Application,
ApplicationSet, and AppProject CRDs into Helm templates so Helm upgrades them
with the rest of the release. A local render of every frozen chart must contain
exactly those three matching CRDs. Do not separately apply upstream CRDs, set
`crds.install=false`, use a CRD from a different application tag, or change only
`global.image.tag`.

The official upgrade overview requires the complete installation set even when
a release appears to need only an image change. Here the complete set is
`helm_release.argocd`, including its chart-templated CRDs and workloads; the
Terraform-owned Bootstrap Seed and Repository Registration are separate
resources and must remain unchanged.

Review the official notes again immediately before each destination hop:

- [upgrade overview](https://argo-cd.readthedocs.io/en/release-3.5/operator-manual/upgrading/overview/)
- [`2.12→2.13`](https://argo-cd.readthedocs.io/en/release-3.5/operator-manual/upgrading/2.12-2.13/)
- [`2.13→2.14`](https://argo-cd.readthedocs.io/en/release-3.5/operator-manual/upgrading/2.13-2.14/)
- [`2.14→3.0`](https://argo-cd.readthedocs.io/en/release-3.5/operator-manual/upgrading/2.14-3.0/)
- [`3.0→3.1`](https://argo-cd.readthedocs.io/en/release-3.5/operator-manual/upgrading/3.0-3.1/)
- [`3.1→3.2`](https://argo-cd.readthedocs.io/en/release-3.5/operator-manual/upgrading/3.1-3.2/)
- [`3.2→3.3`](https://argo-cd.readthedocs.io/en/release-3.5/operator-manual/upgrading/3.2-3.3/)
- [`3.3→3.4`](https://argo-cd.readthedocs.io/en/release-3.5/operator-manual/upgrading/3.3-3.4/)
- [`3.4→3.5`](https://argo-cd.readthedocs.io/en/release-3.5/operator-manual/upgrading/3.4-3.5/)
- [argo-helm CRD lifecycle](https://github.com/argoproj/argo-helm#custom-resource-definitions)

If newer official notes add a precondition for one of these exact releases,
stop and update this repository before live execution. Do not substitute a
newer patch without a separately reviewed repository change.

## Preconditions before every hop

Record the source/destination chart and application versions, Kubernetes
version, exact Git revisions of this repository and the reconciled Application
graph, operator, approver, and evidence timestamp. Then complete all of these:

1. Read the destination application notes and argo-helm chart changelog. Resolve
   every applicable table item and record each item found not applicable with
   the read-only query or repository evidence supporting that conclusion.
2. Export Argo CD disaster-recovery data and record its protected location and
   checksum. This is mandatory for the `2.14.11→3.0.12` hop and must be refreshed
   if the Application graph, projects, repositories, or configuration changed.
3. Record all Applications, AppProjects, ApplicationSets, repository and
   repository-credential Secrets, cluster registrations, Argo CD configuration
   ConfigMaps, and installed CRDs. Confirm no reconciliation, sync, refresh, or
   repository operation is still running.
4. Establish the complete exit-gate baseline below. Capture current component
   images and replicas, API and UI access, repository connection results, and
   every Application's name, project, sync status, health status, revision, and
   operation state.
5. Confirm ownership invariants from configuration and the full plan:
   `kubectl_manifest.argocd_bootstrap_applications` remains the Terraform-owned
   Bootstrap Seed; `kubernetes_secret.argocd_repo_secret` remains the
   Terraform-owned bootstrap Repository Registration; Explicit Secrets remain
   Terraform-managed; the root bootstrap Application remains automatic; and
   every child Application remains manual with no automated sync policy.
6. Change only `argocd_version` to the next chart in the table. Generate a full,
   saved platform plan through `scripts/terraform-local`; never use `-target`.
   The plan must update only `helm_release.argocd` to the exact next chart and
   matching application/CRDs. Any change to the Bootstrap Seed, Repository
   Registration, Explicit Secret data, child graph or sync policy, ingress
   identity, or unrelated service stops the hop.
7. Render the destination chart locally with the same values and verify the
   exact chart/app metadata, all three CRDs, and every expected component image.
   Record artifacts and checksums with the saved plan. Obtain explicit human
   authorization for that exact plan; changed or stale evidence invalidates it.

These checks inspect Live State but do not mutate it. Repository preparation
must stop after non-mutating formatting, validation, and local chart rendering;
it must not generate a live plan, perform an apply, run Helm against the
cluster, apply CRDs, sync an Application, or alter a Secret or repository.

## Additional `2.14→3.0` major-version gate

Before authorizing chart `8.2.7`, follow every detection/remediation section in
the official `2.14→3.0` guide and record at least these results:

- Update fine-grained Application `update`/`delete` subresource RBAC and grant
  explicit `logs, get` permissions wherever existing access must continue.
- Migrate dashboards and alerts off removed legacy application metrics; audit
  Dex subjects if Dex SSO is enabled.
- Prove repositories are registered as Secrets, not legacy `argocd-cm` entries.
  Preserve both the Terraform-owned bootstrap Repository Registration and the
  Argo-managed downstream Repository Registration without transferring either.
- Detect affected nested ApplicationSet selectors and remediate them before the
  upgrade. Record whether ApplicationSets exist even when static inspection
  found none.
- Audit bundled Helm breaking changes, resource exclusions, resource tracking,
  status/health consumers, plugin environment variables, and ignore-difference
  behavior. Record any compatibility setting deliberately retained.
- Confirm monitoring and operational clients tolerate the changed API, metric,
  and health behavior. Upgrade the Argo CD CLI used for verification to the
  destination major version.

The current repository uses Secret-based registrations; that static observation
does not replace the live audit.

## Observable exit gate after every hop

Do not advance until every item passes simultaneously and its output is saved:

- **Release and CRDs:** `helm list -n argocd` reports the exact destination
  chart/application pair with status `deployed`. The Applications,
  ApplicationSets, and AppProjects CRDs are Established, match the destination
  chart schemas, have expected served/storage versions, and report no conversion
  or reconciliation errors. Helm still owns and keeps all three.
- **Application controller:** the `argocd-application-controller` StatefulSet
  has all desired replicas updated, ready, and available. Its logs contain no
  cache, comparison, Kubernetes API, health, sync, or reconciliation failure.
- **API server and UI:** the `argocd-server` Deployment is fully updated and
  available. The public HTTPS hostname resolves to the existing ingress, its
  certificate validates, the login page loads, authentication succeeds, and a
  read-only API/CLI query using a destination-compatible client succeeds.
- **Repository server:** the `argocd-repo-server` Deployment is fully updated
  and available. Manifest generation succeeds for every Application source;
  logs contain no Git, Helm, Kustomize, cache, TLS, credential, or rendering
  failures.
- **ApplicationSet, notifications, Dex, and Redis:** every component enabled by
  the rendered chart is fully updated and ready. For this non-HA configuration,
  require the Redis Deployment and its Secret-dependent consumers to be ready;
  if live values enable another topology, validate every rendered member. Logs
  and events contain no unexpected restart or controller error.
- **Repository connections:** the Terraform-owned bootstrap Repository
  Registration and every Argo-managed downstream registration still exist with
  the same owner and non-sensitive metadata. Every registered repository and
  cluster connection reports successful connectivity; no credential is copied,
  rotated, or exposed in evidence.
- **Bootstrap graph:** `argocd-bootstrap` still uses project `default`, the same
  repo/path/revision and destination, and automated prune/self-heal. It is
  `Healthy` and `Synced`. The expected AppProject, Application Namespaces,
  Repository Registration, and child Applications remain reachable from it.
- **Applications:** the complete Application inventory has no missing or extra
  object. Every Application is `Healthy` and `Synced` at its intended revision
  with no active or failed operation. Every child Application still lacks an
  automated sync policy; do not sync a child merely to manufacture a passing
  gate. Investigate any health change introduced by the destination.
- **Configuration and ownership:** Argo CD ConfigMaps, cluster/repository
  Secrets, Explicit Secrets, and the Bootstrap Seed have no unintended data,
  label, annotation, owner-reference, or field-manager change. Terraform and
  Argo CD retain their documented ownership boundary.

Also repeat the production runbook's broader ingress and Application Workload
functional checks. A ready Argo CD control plane is not enough if it cannot
render the graph or correctly observe its managed workloads.

## Stop and recovery behavior

On any failed preflight, plan review, CRD update, rollout, API/UI test,
repository test, Application health/sync check, or ownership check, stop before
changing the version again. Preserve Live State and evidence, diagnose the
failed hop, follow that destination's supported recovery guidance, and rerun the
complete gate after repair. Do not assume changing `argocd_version` backward is
a safe rollback, and do not repair the graph by changing ownership or enabling
automatic child sync.

Advance only after the current row's exit gate passes and fresh approval is
recorded. After `10.2.3/3.5.0`, repeat the complete platform health, storage,
ingress, Application, functional, and fresh-backup checks before requesting the
platform-completion approval gate.
