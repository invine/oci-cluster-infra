# 26 — Upgrade the control plane to v1.35.2

**What to build:** Revalidate OCI, obtain Approval Gate 3 for the exact full plan, and move only the production OKE control plane from `v1.34.2` to `v1.35.2`.

**Blocked by:** 25 — Upgrade Argo CD to 3.5.0 and approve platform completion

**Status:** ready-for-human

- [ ] OCI is re-queried immediately before planning and still offers exact next version `v1.35.2`.
- [ ] The full plan changes only the control-plane version; the sole worker entry remains fixed at `v1.34.2`.
- [ ] Approval Gate 3 binds explicit human authorization to that exact plan and current health evidence.
- [ ] The OCI work request completes and the cluster returns to `ACTIVE` on exactly `v1.35.2`.
- [ ] Node, system component, API/admission, platform, Longhorn, Argo, ingress, Application Workload, and backup-storage checks pass after the hop.
- [ ] A failed or indeterminate work request pauses for OCI diagnosis and forward recovery; no control-plane downgrade is attempted.
