# Upgrade production OKE to Kubernetes v1.36.1

This is the controlling runbook for the production OKE upgrade from Kubernetes
`v1.34.2` to the frozen target `v1.36.1`. Use a private copy of
[`oke-v1.36.1-evidence-template.md`](oke-v1.36.1-evidence-template.md) as the
execution record. The service-specific runbooks supply the detailed hop
procedures; this runbook owns their order, approval boundaries, stop behavior,
worker migration, and final handoff.

> **Repository Preparation is not Live Cluster Execution.** A ready or resolved
> repository ticket, merged configuration, successful validation, reviewed
> document, or operator possession of this package never authorizes a live
> mutation. Every Terraform apply or state change, CRD or Helm change, OKE work
> request, worker-pool change, Kubernetes cordon or drain, Longhorn scheduling
> or engine change, and Argo CD mutation requires explicit human authorization
> for that action and its current evidence. The six named gates below do not
> replace the action-level authorizations required between them.

## Authorization domains and package prerequisites

**Repository Preparation** may edit and review tracked configuration and
documentation and run local, non-mutating formatting, validation, rendering,
syntax, link, and diff checks. It stops before a live plan, apply, state command,
Argo sync, or OCI, Kubernetes, Infrastructure State, Platform State, or Argo CD
mutation.

**Live Cluster Execution** begins only when a named operator has received
explicit human authorization for the exact next action. Before execution, all
of preparation tickets 13 through 19 must be resolved and the following
artifacts must exist at the same reviewed Git revision:

- Infrastructure configuration with independent control-plane and version-keyed
  worker-pool inputs, exact image validation, the declarative old-pool address
  move, and worker destruction protection;
- [`longhorn-upgrade.md`](longhorn-upgrade.md);
- [`velero-upgrade.md`](velero-upgrade.md);
- [`cert-manager-upgrade.md`](cert-manager-upgrade.md);
- [`f5-nginx-ingress-upgrade.md`](f5-nginx-ingress-upgrade.md); and
- [`argocd-upgrade.md`](argocd-upgrade.md).

If an artifact, frozen pin, matching CRD mechanism, validation result, or
resolved prerequisite is absent, stop in Repository Preparation. Do not fill a
gap during a live window.

## Accepted posture and immutable sequence

The risk owner accepts bounded Application Workload interruptions caused by the
current singleton, `Recreate`, StatefulSet, and Longhorn `ReadWriteOnce` design.
This acceptance does not permit forced deletion or bypassing a health gate.
Velero and Kopia restoreability is **unproven** because this upgrade performs no
restore rehearsal. Fresh successful backups prove backup creation and External
Backup Store access only.

Execute in this order, without combining phases or substituting versions:

1. pass the starting baseline and preserve the existing worker-pool state
   address;
2. upgrade Shared Platform Services serially: Longhorn, Velero, cert-manager,
   F5 NGINX Ingress Controller, then Argo CD;
3. upgrade the control plane `v1.34.2 → v1.35.2 → v1.36.1`;
4. create one three-node `v1.36.1` worker pool directly; never create a
   `v1.35.2` worker pool;
5. qualify the new pool and migrate one old worker at a time;
6. pass Migration Acceptance;
7. weaken old-pool destruction protection in a no-change phase, then retire
   only the `v1.34.2` pool in a separate destruction-only phase; and
8. verify the remaining cluster and hand off the complete evidence package.

Never downgrade the OKE control plane. Worker-only rollback remains available
only while the old pool exists.

## Evidence and approval contract

Create a private evidence directory outside the tracked repository with process
umask `077`, directory mode `0700`, and file mode `0600`. Keep real tfvars,
Terraform state and backups, saved plans, generated kubeconfigs, credentials,
raw command output containing identifiers or sensitive data, and completed
evidence records untracked. They are **Local Sensitive Artifacts**. Record only
redacted references or checksums in review systems; never commit secret values
or sensitive evidence. Confirm `git status --short` before every repository
commit and at handoff.

Every evidence snapshot records:

- UTC timestamp, operator, approver, cluster OCID/name and region, evidence
  directory reference, and incident/change reference;
- exact infrastructure and application Git revisions, including the reconciled
  Application Workload revisions;
- current control-plane version/state, both worker generations, exact image
  OCIDs, node identities, placement, readiness, and intended pool membership;
- the phase-specific OCI, Kubernetes, Longhorn, Velero/Kopia, Argo CD, ingress,
  endpoint, and functional results required below; and
- for Terraform, the root, full command, saved-plan private path, SHA-256,
  creation time, configuration revision, provider lock-file checksum, complete
  effect summary, reviewer, decision, and approval time.

An approval applies only to the exact saved full plan and evidence named in its
record. It is invalidated by relevant drift; any failed or stale check; any
configuration, provider, variable, image, CRD, or plan change; plan
regeneration; a change in OCI version availability or worker-skew support; a
changed node identity or placement; or a materially changed reconciled
Application Workload revision. Stop, refresh the complete affected gate, and
obtain new approval. Approval never survives an unexplained discrepancy.

### Six named approval gates

| Gate | Boundary | Minimum bound evidence |
| --- | --- | --- |
| **1 — Starting Baseline** | Before the first state-address or platform mutation | Complete baseline, fresh backups, no unexplained drift, and the state-address preservation plan |
| **2 — Platform Complete** | After all service hops and before any control-plane plan/apply | Exact final platform versions and CRDs, all service exit gates, complete cluster/workload/functional health, and fresh backups |
| **3 — v1.35.2 Control Plane** | Before applying the first control-plane hop | Current Gate 2 health, OCI offering `v1.35.2`, exact full Infrastructure plan, expected effects, and old-pool preservation |
| **4 — v1.36.1 Control Plane** | Before applying the second control-plane hop | `ACTIVE` `v1.35.2` cluster, repeated complete health, OCI offering exact `v1.36.1`, revalidated temporary `v1.34.2` worker skew, and exact full plan |
| **5 — First Old-Worker Cordon** | After new-pool qualification and before changing scheduling on any old worker | Three qualified new workers, all required DaemonSets, storage/application/functional/backup health, and re-resolved old-worker identity/risk order |
| **6 — Migration Acceptance** | After all migrations and before weakening deletion protection | Everything placed and healthy on the new pool, no Longhorn engine/replica on old workers, post-migration backups, and explicit recognition that retirement removes worker rollback |

A gate failure pauses progression indefinitely; elapsed time does not authorize
an abort, bypass, or next phase.

## Full-plan review rules

Use the repository's Terraform wrapper and a **full** plan for the relevant
root. `-target`, targeted applies, unsaved plans, and plans not made from the
recorded revision are prohibited. Review externally observable resource
effects, not merely Terraform expression changes. Fail closed if a plan:

- contains unexplained or unrelated drift;
- replaces or destroys a protected resource outside the explicitly authorized
  old-pool retirement phase;
- changes Explicit Secret data;
- selects an unapproved Kubernetes version, platform release, CRD set, plugin,
  worker image, OS family, node count, or placement;
- replaces or changes the identity, selectors, address, or Generated OCI Load
  Balancer behind the ingress Service; or
- differs from the phase's expected effects below.

| Phase | Expected full-plan effects |
| --- | --- |
| Existing-pool address preservation | State address moves to the `v1.34.2` map entry with no OCI mutation; the immediately following full plan is empty |
| Platform hop | Only the named service's exact next Helm/CRD/configuration set changes; no unrelated platform resource or Explicit Secret changes |
| `v1.35.2` control plane | Only the OKE control plane advances to `v1.35.2`; the `v1.34.2` worker entry, image, size, and placement remain unchanged |
| `v1.36.1` control plane | Only the OKE control plane advances to exact `v1.36.1`; the retained `v1.34.2` pool remains unchanged |
| New worker pool | Adds only one three-node `v1.36.1` pool with the exact reviewed image and placement; does not create `v1.35.2` workers or change the old pool |
| Remove old-pool protection | Both pool entries remain configured and the plan reports no live resource change |
| Retire old pool | Destroys only the `v1.34.2` worker pool; any other effect stops retirement |

## Gate 1 — Starting Baseline and state-address preservation

Record and require all of the following simultaneously:

- the control plane is `ACTIVE` on `v1.34.2`; exactly three intended old workers
  are `Ready` on `v1.34.2`; current OCI availability and worker skew are
  supported; exact old-pool image metadata and placement match the reviewed
  configuration;
- observed APIs, admission components, all Shared Platform Services, controllers,
  non-completed pods, and every Argo CD Application are healthy; Applications
  are `Healthy` and `Synced` at the recorded revisions;
- all five Longhorn volumes have exactly three healthy replicas, with ready
  nodes/disks and no rebuild, migration, attachment, engine, backup, restore, or
  other storage operation pending;
- the F5 NGINX Service identity, selectors, OCI Load Balancer address/backends,
  all declared HTTP/TLS endpoints, Echo, OpenVPN connection/private reachability,
  Vaultwarden login/read access, and Medusa storefront/backend, PostgreSQL,
  Redis, uploads, and persistent read/write checks pass;
- fresh immutable Velero backups for `staging`, `vaultwarden`, and `openvpn` are
  `Completed` with zero errors and warnings; each included namespace and
  timestamp is recorded; all corresponding Kopia BackupRepositories are
  `Ready`; and the Backup Storage Location is `Available`; and
- full Infrastructure and Platform plans contain no unexplained drift.

Gate 1 approval binds this evidence to the full Infrastructure plan that shows
only declarative preservation of the existing pool at its new address. After
separate authorization, apply that exact plan, record the state result, and
require a subsequent full no-change plan. Any OCI resource mutation or nonempty
follow-up plan stops execution.

## Shared Platform Service sequence and Gate 2

Upgrade one service and one documented hop at a time on Kubernetes `v1.34.2`.
For every hop, follow its linked runbook for official prechecks, matching CRD
lifecycle, full Platform plan, separate action approval, rollout, engine or
manual steps, exit checks, and evidence. Do not start the next hop until the
complete current exit gate passes.

1. **Longhorn:** `1.7.2 → 1.8.2 → 1.9.2 → 1.10.2 → 1.11.3 →
   1.12.0`.
2. **Velero:** chart/app/AWS-plugin sets
   `8.7.2/1.15.2/1.11.1 → 10.1.3/1.16.2/1.12.2 →
   11.4.0/1.17.1/1.13.2 → 12.1.0/1.18.1/1.14.2`; matching server,
   node-agent, restore-helper, plugin images, and pre-Helm CRDs move together.
3. **cert-manager:** `v1.16.1 → v1.17.4 → v1.18.6 → v1.19.6 →
   v1.20.3 → v1.21.1`, with confirmed Helm CRD ownership and matching CRDs.
4. **F5 NGINX Ingress Controller:** chart/application
   `1.4.0/3.7.0 → 1.4.2/3.7.2 → 2.0.1/4.0.1 → 2.6.4/5.5.4`,
   matching major-version CRDs, and unchanged Service and Load Balancer identity.
5. **Argo CD:** chart/application
   `7.6.12/2.12.6 → 7.7.23/2.13.4 → 7.9.1/2.14.11 →
   8.2.7/3.0.12 → 9.0.6/3.1.9 → 9.3.7/3.2.6 →
   9.5.11/3.3.9 → 10.2.2/3.4.6 → 10.2.3/3.5.0`, including the
   complete release and matching CRDs while preserving the Bootstrap Seed,
   Repository Registration, Explicit Secrets, and manual child sync policy.

After every hop, record the exact chart/application/CRD/image set, plan and
apply, rollout and component status, service-specific storage/repository/
certificate/ingress/Application checks, and affected user-visible checks.
Refresh the complete Gate 1 health set and fresh backups after the final Argo CD
hop. Gate 2 approves the completed platform state, not permission to change the
control plane.

## Gates 3 and 4 — Control-plane hops

For **Gate 3**, query OCI against the current cluster and record the exact
offered path to `v1.35.2`. Generate a full Infrastructure plan whose only live
effect is the control-plane hop and whose old-pool entry is unchanged. Bind
approval to that plan and the current Gate 2 evidence. After separate apply
authorization, submit the work request, record its ID and timestamps, and wait
for success and an `ACTIVE` cluster reporting exact `v1.35.2`. A failed or
indeterminate work request stops for OCI diagnosis and supported forward repair;
never attempt a downgrade. Rerun the complete health set.

For **Gate 4**, query OCI again from the `v1.35.2` cluster. Require OCI to offer
exact `v1.36.1` and explicitly revalidate that temporary `v1.34.2` workers remain
supported. If either condition fails, leave the healthy cluster at `v1.35.2`
and reopen target selection. Otherwise review and approve a full plan whose only
effect is the exact second control-plane hop. After separately authorized
execution, require a successful work request and `ACTIVE` exact `v1.36.1`, then
rerun the complete health set. The old workers remain unchanged.

## Create and qualify the v1.36.1 worker pool

Re-query exact approved OKE image metadata and OCI placement/capacity. Review a
full Infrastructure plan that adds only three direct `v1.36.1` workers and
retains the old entry unchanged. After separate authorization and apply, record
pool/work-request IDs, image OCID, availability-domain placement, and the three
new node identities. Require all three nodes `Ready` on exact `v1.36.1` and all
required OCI CNI, kube-proxy, OCI CSI, Longhorn manager/CSI/engine-image, F5
NGINX, and Velero node-agent DaemonSets ready on them. Require new Longhorn nodes
and disks ready, schedulable, and sufficiently capacitated, then rerun the full
storage, Argo, endpoint, functional, repository, and backup checks.

Do not touch an old worker until Gate 5 passes.

## Gate 5 and serial worker migration

The stored risk order is exact for the observed August 2026 placement:

1. `10.0.4.31` — canary; exercises OpenVPN's `ReadWriteOnce` volume and UDP path;
2. `10.0.5.209` — exercises Medusa backend and uploads; and
3. `10.0.5.148` — last; observed hosting PostgreSQL, Redis, Vaultwarden, and most
   stateful Application Workloads.

Immediately before Gate 5, re-resolve each live Kubernetes node name, provider
ID, private IP, pool OCID, Longhorn node, disks, volumes, replicas, engines,
ordinary pods, and placement rationale. The addresses are risk evidence, not
durable identities. Any changed identity or placement invalidates the stored
order; stop, reassess risk, record a new rationale, and reacquire Gate 5.

For exactly one selected old worker at a time:

1. confirm explicit authorization for this worker and current evidence;
2. disable Longhorn replica scheduling only on its resolved Longhorn node;
3. cordon it, then drain through the eviction API while ignoring DaemonSets and
   respecting all safety controls; never force-delete a pod;
4. wait for affected workloads and platform replicas on the new pool;
5. require every Longhorn volume to return to exactly three healthy replicas,
   no engine or replica on the drained node, and no pending operation;
6. require all Applications `Healthy`/`Synced`, affected controllers and pods
   ready, Service endpoints and Load Balancer backends healthy; and
7. repeat all affected functional checks, including HTTP/TLS, OpenVPN and private
   reachability, Vaultwarden login/read, and Medusa storefront/backend,
   PostgreSQL, Redis, uploads, and persistent read/write behavior.

Record start/end times, resolved identity and before/after placement, commands,
evictions, interruption, rebuild/reattach observations, checks, and approval.
Only a complete pass authorizes consideration of the next worker.

### Worker-only rollback

Consider rollback for Longhorn degradation/fault, volume attachment or data
failure, unstable new workers, or an Application Workload that cannot recover.
Stop all drains; retain both Terraform pool entries; cordon the involved new
workers; re-enable Longhorn scheduling and uncordon the required old workers;
then evict affected workloads from new workers one at a time without forced
deletion. Wait for detach/reattach and three healthy replicas on supported old
placement, and rerun Argo, storage, ingress, endpoint, and functional checks.

The control plane remains `v1.36.1`. Retain failed new workers cordoned for
diagnosis. Repairing, replacing, or deleting them is a later reviewed,
explicitly authorized change.

## Gate 6 — Migration Acceptance and old-pool retirement

Require all of the following simultaneously:

- every ordinary workload pod runs on the new pool; only expected DaemonSets
  remain on cordoned old workers;
- no Longhorn engine or replica remains on an old worker; all five volumes have
  exactly three healthy new-pool replicas with no pending operation;
- all three new workers, required platform DaemonSets, controllers, non-completed
  pods, and Shared Platform Services are ready;
- every Argo CD Application is `Healthy` and `Synced` at its recorded revision;
- Service endpoints, F5 NGINX Service/Load Balancer identity and backends, every
  HTTP/TLS endpoint, Echo, OpenVPN, Vaultwarden, and all Medusa checks pass; and
- new post-migration `staging`, `vaultwarden`, and `openvpn` backups are
  `Completed` without warnings/errors, Kopia repositories are `Ready`, and the
  Backup Storage Location is `Available`.

Gate 6 approval explicitly accepts that weakening protection and deleting the
old pool crosses the final worker-rollback boundary. Restoreability remains
unproven.

Retirement is two separate reviewed changes and authorizations:

1. while both map entries remain, remove only destruction protection and require
   a full no-change plan before applying the configuration change; then
2. remove only the `v1.34.2` entry and require a full plan destroying only that
   pool before applying it.

Record both plans, approvals, applies, and OCI work requests. After OCI confirms
deletion, repeat node, pod, DaemonSet, Longhorn, Argo, ingress, application,
repository, Backup Storage Location, and functional checks. Worker rollback is
now unavailable; later failures use supported forward repair and the accepted
backup posture.

## Stop and forward-repair branches

On any failed or ambiguous preflight, plan, approval, work request, rollout,
CRD, health, storage, backup, ingress, Argo, or functional check: stop before
the next mutation, preserve evidence and current Live State, diagnose through
supported vendor guidance, perform only a separately reviewed and explicitly
authorized forward repair, rerun the complete failed gate, and reacquire any
invalidated approval.

- **Shared Platform Service:** do not assume a generic downgrade. Hold at the
  current successful hop and use that release's supported recovery procedure.
- **Control plane:** never downgrade. Hold its last successful version and use
  OCI diagnosis/forward recovery.
- **New-pool provisioning before migration:** keep all old workers untouched;
  repair or abandon only through a later reviewed plan.
- **Worker migration:** use worker-only rollback while the old pool exists.
- **After old-pool deletion:** use forward repair; the runbook has no worker
  rollback branch and backups still do not establish restoreability.

## Final verification and handoff

The named operator and receiving owner review the completed private evidence
record and sign the handoff. Record final control-plane and worker versions;
platform chart/application/CRD/plugin versions; worker image OCIDs and final
placement; every plan, checksum, apply and OCI work request; service-hop and
node-migration evidence; functional and post-removal results; backup names,
times, namespaces, repository and storage-location status; all approvals; and
any incident or forward-repair references.

Carry these residual risks verbatim into handoff:

- Velero/Kopia restoreability remains unproven because no restore rehearsal was
  performed;
- bounded Application Workload interruptions were accepted for singleton and
  `ReadWriteOnce` workloads; and
- worker-only rollback was permanently lost when the old pool was deleted.

The upgrade is complete only when all final checks pass and a named owner accepts
the evidence package and residual risks. Otherwise it remains paused with the
current safe state, owner, and next authorized action recorded.
