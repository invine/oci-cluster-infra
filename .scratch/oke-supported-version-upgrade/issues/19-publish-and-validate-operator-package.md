# 19 — Publish and validate the operator package

**What to build:** Publish one durable operator package that binds the prepared Infrastructure and Shared Platform Service changes into the approved sequence, evidence contract, approval gates, rollback behavior, and final handoff.

**Blocked by:** 13 — Represent control-plane and worker generations independently; 14 — Prepare the Longhorn upgrade path; 15 — Prepare the Velero upgrade path; 16 — Prepare the cert-manager upgrade path; 17 — Prepare the F5 NGINX upgrade path; 18 — Prepare the Argo CD upgrade path

**Status:** ready-for-agent

- [ ] The runbook separates Repository Preparation from Live Cluster Execution and states that ticket readiness never authorizes a live mutation.
- [ ] It orders platform services as Longhorn, Velero, cert-manager, F5 NGINX Ingress Controller, and Argo CD before control-plane work.
- [ ] It includes control-plane hops `v1.34.2 → v1.35.2 → v1.36.1`, direct creation of a `v1.36.1` worker pool, serial migration, Migration Acceptance, and guarded old-pool retirement.
- [ ] It defines all six evidence-bound approval gates and the events that invalidate approval.
- [ ] It supplies phase-specific evidence fields, expected full-plan effects, fail-closed plan review rules, stop behavior, worker-only rollback, and forward-repair branches.
- [ ] It includes the exact worker risk order but requires live identities and placement rationale to be re-resolved before execution.
- [ ] It records unproven restoreability, accepted bounded Application Workload interruptions, and the loss of worker rollback after old-pool deletion.
- [ ] Local Sensitive Artifacts and sensitive evidence are explicitly excluded from tracking and retain restrictive permissions.
- [ ] Terraform formatting and non-mutating validation pass for both roots; no automated test suite is added and no live plan, apply, state mutation, Argo sync, or cluster mutation is performed.
