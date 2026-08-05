# 19 — Publish and validate the operator package

**What to build:** Publish one durable operator package that binds the prepared Infrastructure and Shared Platform Service changes into the approved sequence, evidence contract, approval gates, rollback behavior, and final handoff.

**Blocked by:** 13 — Represent control-plane and worker generations independently; 14 — Prepare the Longhorn upgrade path; 15 — Prepare the Velero upgrade path; 16 — Prepare the cert-manager upgrade path; 17 — Prepare the F5 NGINX upgrade path; 18 — Prepare the Argo CD upgrade path

**Status:** resolved

- [x] The runbook separates Repository Preparation from Live Cluster Execution and states that ticket readiness never authorizes a live mutation.
- [x] It orders platform services as Longhorn, Velero, cert-manager, F5 NGINX Ingress Controller, and Argo CD before control-plane work.
- [x] It includes control-plane hops `v1.34.2 → v1.35.2 → v1.36.1`, direct creation of a `v1.36.1` worker pool, serial migration, Migration Acceptance, and guarded old-pool retirement.
- [x] It defines all six evidence-bound approval gates and the events that invalidate approval.
- [x] It supplies phase-specific evidence fields, expected full-plan effects, fail-closed plan review rules, stop behavior, worker-only rollback, and forward-repair branches.
- [x] It includes the exact worker risk order but requires live identities and placement rationale to be re-resolved before execution.
- [x] It records unproven restoreability, accepted bounded Application Workload interruptions, and the loss of worker rollback after old-pool deletion.
- [x] Local Sensitive Artifacts and sensitive evidence are explicitly excluded from tracking and retain restrictive permissions.
- [x] Terraform formatting and non-mutating validation pass for both roots; no automated test suite is added and no live plan, apply, state mutation, Argo sync, or cluster mutation is performed.

## Comments

- 2026-08-06 published `docs/runbooks/oke-v1.36.1-upgrade.md` as the
  controlling operator runbook and `docs/runbooks/oke-v1.36.1-evidence-template.md`
  as the copyable private evidence contract.
- The package binds the six named gates, approval invalidation rules, exact
  platform/control-plane/worker order, phase plan shapes, fail-closed review,
  serial node migration, worker-only rollback, forward repair, guarded
  retirement, residual risks, and final handoff. It stops in Repository
  Preparation unless tickets 13–19 and every linked service artifact are
  resolved at the reviewed revision.
- `terraform fmt -check -recursive`, `git diff --check`, local Markdown-link
  checks, `terraform -chdir=infra validate`, and
  `terraform -chdir=platform validate` passed. Provider-backed validation was
  rerun outside the filesystem sandbox after sandboxed provider startup failed.
- No automated test suite was added. No Terraform plan, apply, state command,
  OCI work request, Helm/CRD action, Argo sync, or Kubernetes/cluster mutation
  was performed.
- The required two-axis review found and then verified fixes for the audited
  Application Workload revision baselines, per-worker Echo evidence, and the
  Local Sensitive Artifact vocabulary. Final Standards and Spec re-reviews
  reported no findings. `CONTEXT.md` now reflects the approved sensitive-artifact
  categories used by the operator package.
