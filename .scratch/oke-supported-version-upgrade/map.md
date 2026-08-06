# Plan the OKE upgrade to the newest jointly supported Kubernetes version

Label: wayfinder:map

## Destination

An approval-ready, rollback-defined plan to upgrade the production OKE cluster from Kubernetes `v1.34.2` to the frozen jointly supported target `v1.36.1`. The plan ends before any live mutation.

## Notes

- Treat August 4, 2026 as the target-selection freeze date; a later OKE release requires fresh compatibility research and approval.
- Consult the `research`, `grilling`, and `domain-modeling` skills as each ticket requires.
- Use OCI and upstream project primary sources for version and compatibility claims, supplemented by read-only OCI and Kubernetes queries.
- Preserve the ownership boundary: Terraform owns Infrastructure and Shared Platform Services; Argo CD owns Application Workloads.
- The control plane remains on the new version if worker migration fails; only workers roll back to the retained `v1.34.2` pool.
- Use a temporary paid-capacity blue/green pool. Retire the old pool immediately after the Migration Acceptance Gate passes.
- Require fresh successful Velero backups for every stateful Application Workload before the first disruptive step; restoreability is accepted as unproven because no restore rehearsal will be performed.
- Planning only: do not mutate OCI, Kubernetes, Terraform state, or Argo CD.

## Decisions so far

- [Determine OKE target candidates and upgrade constraints](issues/01-determine-oke-target-candidates.md) — OKE offers `v1.36.1` regionally; this cluster must first upgrade from `v1.34.2` to `v1.35.2`, then re-query OCI before the `v1.36.1` hop.
- [Establish the Shared Platform Service compatibility ceiling](issues/02-establish-platform-compatibility-ceiling.md) — Kubernetes 1.36 is the joint ceiling, requiring staged upgrades of all five critical services with explicit Velero and Longhorn evidence caveats.
- [Audit live upgrade readiness and Kubernetes API removals](issues/03-audit-upgrade-readiness-and-api-removals.md) — readiness is blocked on live/API/workload checks; the image fallback, strict Longhorn placement, and unproven Velero restore path are material gates.
- [Audit Argo workload disruption readiness](issues/09-audit-argo-workload-disruption-readiness.md) — the exact reconciled manifests make literal zero downtime impossible: all workloads are singletons, several use `Recreate`, no PDBs exist, and five Longhorn PVCs are `ReadWriteOnce`.
- [Select the exact Kubernetes target and hop sequence](issues/04-select-target-and-hop-sequence.md) — lock control-plane hops `v1.34.2 → v1.35.2 → v1.36.1`, then create the replacement worker pool directly at `v1.36.1` while retaining `v1.34.2` workers for worker-only rollback.
- [Reconcile zero downtime with singleton Application Workloads](issues/12-reconcile-zero-downtime-with-singleton-workloads.md) — accept bounded maintenance interruptions, migrate and validate workloads serially where practical, and retain worker-only rollback until the Migration Acceptance Gate passes.
- [Choose the representative stateful restore rehearsal](issues/05-choose-restore-rehearsal.md) — skip restore rehearsal, accept unproven restoreability, and retain a fail-closed fresh-backup gate for `staging`, `vaultwarden`, and `openvpn`.
- [Set temporary capacity and maintenance guardrails](issues/07-set-capacity-and-maintenance-guardrails.md) — impose no bespoke time, cost, quota-reservation, abort-duration, or cleanup limits; rely on successful three-node provisioning and the existing backup, health, acceptance, and rollback gates.
- [Decide Shared Platform Service upgrade pins and order](issues/10-decide-platform-upgrade-pins-and-order.md) — freeze exact serial hops for Longhorn, Velero, cert-manager, F5 NGINX Ingress, and Argo CD; complete every CRD-aware hop and validation gate on Kubernetes `v1.34.2` before upgrading the control plane.
- [Define worker migration and rollback gates](issues/06-define-worker-migration-gates.md) — drain old workers one at a time in increasing stateful risk, rebuild three healthy Longhorn replicas after each, pause before rollback, and delete the old pool only after workload, ingress, storage, Argo, functional, and post-migration backup gates pass.
- [Decide Terraform target and worker-pool lifecycle representation](issues/11-decide-terraform-target-and-pool-lifecycle.md) — separate control-plane and worker versions, model pools as version-keyed generations with exact pinned and validated OKE images, preserve the existing pool through a declarative state move, and require fail-closed destruction protection plus a two-change retirement gate.
- [Decide the upgrade order and operator runbook gates](issues/08-decide-upgrade-order-and-runbook-gates.md) — execute platform upgrades, two irreversible control-plane hops, blue/green worker migration, acceptance, and guarded old-pool retirement through six evidence-bound approval gates with explicit pause, worker-only rollback, and forward-repair branches.
- [Remediate the paused Gate 1](issues/20-pass-starting-gate-and-migrate-pool-state-address.md) — distinguish Candidate from Retained Worker Pools, give Terraform exclusive OCI security-list ownership, preserve Terraform management of the kubeconfig behind semantic comparison, and bind approval to a machine-validated saved full plan before retrying the state-address migration.
- [Prepare the Gate 1 plan remediation](issues/35-prepare-gate-1-plan-remediation.md) — implement exact disposition-aware worker image validation, the exclusive-owner annotation, a fail-closed saved-plan validator with fixtures, and the ticket 36 prerequisite without changing Infrastructure State, Platform State, or Live State.

## Not yet specified

- Nothing; the route to the planning destination is fully specified.

## Out of scope

- Performing the live control-plane, Shared Platform Service, or worker upgrade; this effort ends at an approved plan.
- Downgrading or rolling back the upgraded OKE control plane.
- Unrelated component modernization, infrastructure refactors, or ownership changes.
- Redesigning Application Workloads for high availability solely to eliminate upgrade downtime; bounded maintenance interruptions are accepted for this effort.
- Performing a pre-upgrade Velero restore rehearsal; this effort accepts unproven restoreability and relies on fresh backup evidence plus worker-only rollback.
