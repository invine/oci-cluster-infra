# Decide the upgrade order and operator runbook gates

Type: grilling
Status: resolved
Blocked by: 04, 05, 06, 07, 09, 10, 11, 12

## Question

In what exact order should required Shared Platform Service changes, control-plane hops, worker-pool creation and migration, verification, worker-only rollback, and old-pool removal occur, and where must the operator stop for approval or abort?

## Answer

Execute the upgrade in the phases below. A phase may start only when the previous phase's exit gate passes. Terraform owns Infrastructure and Shared Platform Services; Argo CD continues to own Application Workloads. Do not make ad hoc changes to Argo-managed workload resources to force migration.

Use full Terraform plans throughout; never use `terraform -target`. Review every plan immediately before its apply. A plan that contains unrelated drift, replaces a protected resource, changes Explicit Secret data, selects an unapproved image, replaces the ingress Load Balancer, or includes changes beyond the current phase fails closed.

### 0. Prepare the evidence bundle and changes

Before the maintenance work, prepare the Terraform representation refactor, every frozen Shared Platform Service hop, both control-plane configuration changes, the `v1.36.1` pool entry, functional checks, and an operator evidence log. Record the frozen source revisions, release pins, image OCIDs, current OCI resource identifiers, expected Terraform addresses, and named approver.

This preparation does not authorize a live mutation. A later OKE release, different target patch, platform-pin substitution, worker-image substitution, or reconciled workload revision with materially different behavior requires revalidation and approval.

### 1. Establish the starting baseline — Approval Gate 1

Re-query live OCI and Kubernetes state. Require all of the following before approving the start:

- the cluster is `ACTIVE` on `v1.34.2`, all three existing workers are `Ready` on `v1.34.2`, and OCI still offers exact control-plane hop `v1.35.2`;
- OCI's current version-skew rules permit the retained `v1.34.2` pool through the proposed control-plane sequence; otherwise stop and reopen the target or worker-sequence decision;
- admission webhooks, aggregated APIs, CSI/CNI components, kube-proxy, and all APIs observed in live or reconciled objects are compatible with the next hop, with no unresolved removed/deprecated-API blocker;
- all Shared Platform Services are healthy at their recorded starting versions;
- all five Longhorn volumes have three healthy replicas, every Longhorn node/disk is ready and schedulable, and no rebuild, attachment, engine, or replica operation is pending;
- every Argo CD Application is `Healthy` and `Synced`, all expected pods are ready, ingress and OCI Load Balancer backends are healthy, and the Echo, OpenVPN, Vaultwarden, and Medusa baseline functional checks pass;
- fresh Velero backups for `staging`, `vaultwarden`, and `openvpn` are `Completed` with zero errors and warnings, all corresponding Kopia BackupRepositories are `Ready`, and the Backup Storage Location is available; and
- a full Terraform refresh/plan exposes no unexplained drift or unrelated change.

Record the evidence and obtain explicit Approval Gate 1. No restore rehearsal is performed; the approval must state that restoreability remains unproven.

### 2. Refactor Terraform without replacing the old pool

Implement [Decide Terraform target and worker-pool lifecycle representation](11-decide-terraform-target-and-pool-lifecycle.md): separate the control-plane version, introduce the version-keyed `worker_pools` map, pin and validate exact worker images, enable `prevent_destroy`, remove the unsafe image fallback, and declaratively move the current pool to `worker_pool["v1.34.2"]`.

The baseline plan must show only the intended state-address move and no OCI resource creation, update, replacement, or destruction. Apply it, then run a second full plan that shows no changes. Any proposed live mutation stops this phase.

### 3. Upgrade Shared Platform Services on Kubernetes `v1.34.2`

Execute [Decide Shared Platform Service upgrade pins and order](10-decide-platform-upgrade-pins-and-order.md) completely in this order:

1. Longhorn
2. Velero
3. cert-manager
4. F5 NGINX Ingress Controller
5. Argo CD

Complete and validate every frozen hop of one service before beginning the next. Never combine listed minor-version hops in one apply. Review a full Terraform plan for every hop and execute its service-specific CRD, rollout, storage, backup, certificate, ingress, repository, Argo, and functional gates.

Any failed hop pauses the runbook. Preserve the current state, repair that service according to its own supported recovery procedure, and repeat the entire failed-hop gate. Do not assume a generic platform-service downgrade.

After the last Argo CD hop, rerun the complete starting health, storage, Argo, ingress, application, and fresh-backup checks. Record the final platform pins and evidence.

### 4. Authorize control-plane work — Approval Gate 2

Obtain explicit approval that all Shared Platform Service upgrades are complete and that control-plane planning may begin. Any platform or workload drift since the recorded evidence invalidates this approval.

### 5. Upgrade the control plane to `v1.35.2` — Approval Gate 3

Re-query OCI immediately before planning and require `v1.35.2` to be an offered next version. Keep the only worker-pool entry fixed at `v1.34.2`. Generate a full plan whose only live change is the control-plane version `v1.34.2 → v1.35.2`, attach it to the evidence bundle, and obtain explicit Approval Gate 3.

Apply the plan once. Follow the OCI work request to completion and require the cluster to return to `ACTIVE` on exactly `v1.35.2`. Then rerun node, system component, platform, API/admission, Longhorn, Argo, ingress, application, and backup-storage health checks before advancing.

A failed or indeterminate work request stops the runbook for OCI diagnosis and forward recovery. Never attempt to downgrade the control plane.

### 6. Upgrade the control plane to `v1.36.1` — Approval Gate 4

Only after the `v1.35.2` exit gate passes, re-query the cluster's available Kubernetes versions and OCI's current worker-skew rules. Require exact `v1.36.1` availability and continued support for temporarily retaining `v1.34.2` workers. If either condition fails, park the healthy cluster at `v1.35.2` with its retained workers and reopen target selection; do not substitute another patch.

Generate a full plan whose only live change is `v1.35.2 → v1.36.1`, attach it to the evidence bundle, and obtain explicit Approval Gate 4. Apply once, follow the OCI work request to completion, and require `ACTIVE` on exactly `v1.36.1`. Rerun the same complete post-hop health checks. The control plane remains on `v1.36.1` for all later failure paths.

### 7. Create and qualify the `v1.36.1` worker pool

Re-query the pinned worker image and require its OCID, OKE Kubernetes version, and approved OS family to match exactly. Add `worker_pool["v1.36.1"]` while retaining the protected `v1.34.2` entry. The full plan must create only the new three-node pool; it must not alter or replace the old pool.

Apply, wait for all three new workers to be `Ready`, and execute the complete pre-cordon gate in [Define worker migration and rollback gates](06-define-worker-migration-gates.md), including DaemonSet coverage, Longhorn readiness and capacity, application/Argo health, ingress and functional checks, and fresh successful backups. Successful provisioning of all three nodes is the capacity gate; there is no separate quota, cost, or duration limit.

### 8. Authorize workload migration — Approval Gate 5

Attach the exact new-pool plan/apply evidence and pre-cordon results, then obtain explicit approval before cordoning the first old worker. Any subsequent failed check or relevant state change invalidates approval and stops migration.

### 9. Migrate one old worker at a time

Follow [Define worker migration and rollback gates](06-define-worker-migration-gates.md) exactly. Resolve live node identities again, then process the recorded risk order: `10.0.4.31`, `10.0.5.209`, and `10.0.5.148`. For each node, disable Longhorn replica scheduling, cordon, drain through eviction without forced deletion, recover workloads on the new pool, restore all Longhorn volumes to three healthy replicas, and pass the Argo, endpoint, ingress, storage, and affected functional gates before touching the next node.

Bounded interruptions for singleton, `Recreate`, StatefulSet, and `ReadWriteOnce` workloads are accepted. An interruption is not permission to bypass a gate or force-delete an object.

### 10. Pause or perform worker-only rollback on failure

Any failed provisioning, readiness, eviction, scheduling, Longhorn, Argo, ingress, backup, or functional gate immediately stops later actions regardless of elapsed time. Record evidence, preserve both Terraform pool entries, and first attempt forward repair followed by the complete failed gate.

After migration begins, invoke the worker-only rollback defined in [Define worker migration and rollback gates](06-define-worker-migration-gates.md) when Longhorn is degraded or faulted, volume attachment or data access fails, new workers are unstable, or an affected application cannot be restored to working health on the new pool. Return affected workloads and required Shared Platform Services to uncordoned `v1.34.2` workers, but leave the control plane on `v1.36.1`. Keep the failed new pool cordoned for diagnosis; its repair, replacement, or removal is a separate reviewed Terraform change.

### 11. Pass Migration Acceptance — Approval Gate 6

After all three old workers are drained, execute the complete Migration Acceptance Gate from [Define worker migration and rollback gates](06-define-worker-migration-gates.md). It must prove that ordinary workloads, platform DaemonSets, Longhorn engines and three healthy replicas, Argo Applications, controllers, endpoints, Load Balancer backends, and all declared functional checks are healthy on the new pool. It must also include new post-migration backups for all three stateful namespaces with healthy repositories and storage location.

Record the evidence and obtain explicit Approval Gate 6 before weakening deletion protection. This is the last worker-rollback boundary. Any failure or relevant drift invalidates approval and leaves the protected old pool intact.

### 12. Retire the old pool through two reviewed changes

First, remove `prevent_destroy` while retaining both map entries. Require a full plan with no infrastructure changes. Second, remove only `worker_pool["v1.34.2"]`. Require a fresh full plan showing destruction of only the old pool, then apply it immediately after review.

Wait for OCI deletion to finish. Confirm the old Kubernetes nodes are gone, then repeat node, pod, DaemonSet, Longhorn, Argo, ingress, application, backup-repository, and Backup Storage Location checks. Once OCI deletes the old pool, worker rollback is unavailable; any failure uses forward repair and the accepted backup posture.

### 13. Close and hand off

Record the final control-plane version, worker versions and image OCIDs, Shared Platform Service pins, Terraform plans and applies, OCI work requests, node migration evidence, functional results, backup identifiers, approval records, and post-deletion verification. Explicitly retain these residual-risk statements:

- no Velero restore rehearsal was performed, so restoreability remains unproven;
- the old worker pool has been deleted and worker rollback is no longer available; and
- Application Workloads remain singleton/non-HA where previously identified.

Declare success only after this evidence is complete. Otherwise leave the runbook paused at its last passed gate with a named owner and recorded next action.

### Approval and evidence contract

Each of the six approvals applies only to the exact evidence presented. A failed check, relevant drift, configuration change, newly generated Terraform plan, OCI availability/skew change, or materially changed reconciled workload revision invalidates the approval and requires the affected gate to be rerun. Verbal approval without the recorded evidence bundle is insufficient.

“Stop” means preserve the current state, record evidence, and perform no later runbook step. After repair, rerun the complete failed gate and obtain fresh approval before crossing any named boundary. There is no elapsed-time abort trigger and no control-plane rollback path.
