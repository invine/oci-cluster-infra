# 14 — Prepare the Longhorn upgrade path

**What to build:** Prepare a reviewable, operator-usable Longhorn path from `1.7.2` to `1.12.0` that keeps storage compatibility checks and CRD handling attached to every serial hop without changing Live State.

**Blocked by:** None — can start immediately

**Status:** resolved

- [x] The prepared sequence is exactly `1.7.2 → 1.8.2 → 1.9.2 → 1.10.2 → 1.11.3 → 1.12.0` with no automatic version substitution.
- [x] Every hop identifies its matching chart/application release, official pre-upgrade checks, and CRD lifecycle.
- [x] Every hop defines observable exit checks for managers, CSI components, supporting workloads, nodes, disks, volumes, engines, and replicas.
- [x] Progress requires three healthy replicas for every volume with no rebuild or other storage operation pending.
- [x] The prepared configuration keeps the V2 engine disabled and introduces no unrelated storage migration.
- [x] Terraform formatting and non-mutating validation pass; no platform plan or apply is performed.

## Comments

- 2026-08-06 implementation completed with a frozen `longhorn_version`
  allowlist, explicit pre-upgrade hook settings, V1-only data-engine settings,
  disabled automatic engine upgrades, the official `v1.10.2` backing-image
  manager hotfix, and chart-compatible image repository handling across the
  `v1.10` registry boundary.
- Added `docs/runbooks/longhorn-upgrade.md` with the exact chart/application
  sequence, destination and common official prechecks, per-hop templated CRD
  lifecycle, separate engine-upgrade authorization/procedure, complete
  component and storage exit gates, evidence requirements, and stop behavior.
- `terraform fmt -check -recursive`, `git diff --check`,
  `terraform -chdir=infra validate`, and `terraform -chdir=platform validate`
  passed. All six frozen charts rendered with their matching CRDs, pre-upgrade
  hook, V1-only settings, exact manager/backing-image references, and no doubled
  registry prefix.
- The required two-axis review reported zero hard Standards findings and zero
  Spec findings. No Terraform plan, apply, state command, Helm upgrade,
  Kubernetes mutation, or other Live State change was performed.
