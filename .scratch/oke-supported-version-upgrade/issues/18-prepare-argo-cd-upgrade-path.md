# 18 — Prepare the Argo CD upgrade path

**What to build:** Prepare the complete Argo CD chart/application/CRD sequence to `3.5.0` while preserving Terraform's Bootstrap Seed and Repository Registration and Argo CD's Application graph.

**Blocked by:** None — can start immediately

**Status:** resolved

- [x] The prepared chart/application sequence is exactly `7.6.12/2.12.6 → 7.7.23/2.13.4 → 7.9.1/2.14.11 → 8.2.7/3.0.12 → 9.0.6/3.1.9 → 9.3.7/3.2.6 → 9.5.11/3.3.9 → 10.2.2/3.4.6 → 10.2.3/3.5.0`.
- [x] Each hop upgrades the complete release and its matching CRDs rather than only container images.
- [x] Intervening official upgrade-note requirements are captured as preconditions for their corresponding hops.
- [x] The Bootstrap Seed, bootstrap Repository Registration, Explicit Secrets, and manual child-Application sync policy remain unchanged.
- [x] Every hop defines exit checks for all Argo CD components, API/UI access, repository connections, and every Application's Healthy/Synced state.
- [x] Terraform formatting and non-mutating validation pass; no Helm, CRD, Application, repository, or Secret mutation is performed.

## Comments

- 2026-08-06 implementation completed with an exact `argocd_version`
  allowlist, explicit Helm ownership and retention of all three Argo CD CRDs,
  and an operator runbook for every frozen chart/application hop.
- `docs/runbooks/argocd-upgrade.md` records destination-specific official-note
  preconditions, the major-version audit, ownership and manual-sync invariants,
  full-plan approval boundaries, complete component/API/UI/repository/Application
  exit gates, and stop behavior.
- `terraform fmt -check -recursive`, `git diff --check`,
  `terraform -chdir=infra validate`, and `terraform -chdir=platform validate`
  passed. Official metadata and local renders verified every exact chart/app pair
  and three matching chart-templated CRDs at all nine stages.
- The required two-axis review reported no hard Standards findings and no
  remaining Spec findings. No Terraform plan/apply/state command, Helm upgrade,
  Kubernetes/CRD/Application mutation, repository change, or Secret change was
  performed.
