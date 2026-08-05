# 15 — Prepare the Velero upgrade path

**What to build:** Prepare four coherent Velero upgrade sets so each live hop can advance the chart, server, node agent, restore helper, AWS plugin, and CRDs together while preserving backup access.

**Blocked by:** None — can start immediately

**Status:** resolved

- [x] The four chart/application/AWS-plugin sets are exactly `8.7.2/1.15.2/1.11.1`, `10.1.3/1.16.2/1.12.2`, `11.4.0/1.17.1/1.13.2`, and `12.1.0/1.18.1/1.14.2`.
- [x] Matching server, node-agent, restore-helper, and plugin images are pinned as one coherent set per hop.
- [x] Each hop has a reproducible mechanism to apply CRDs for that exact Velero minor before Helm while automatic CRD upgrades remain disabled.
- [x] The External Backup Store remains external and neither Terraform state attempts to own it.
- [x] Each hop defines exit checks for the Velero Deployment, node-agent DaemonSet, Backup Storage Location, Kopia BackupRepositories, and fresh backups for `staging`, `vaultwarden`, and `openvpn`.
- [x] No restore rehearsal or claim of proven restoreability is added.
- [x] Terraform formatting and non-mutating validation pass; no live backup, CRD, or release mutation is performed.

## Comments

- 2026-08-06 implementation completed with one validated `velero_version`
  stage selecting the chart, server/node-agent image, restore helper, and AWS
  plugin as a coherent frozen release set.
- Added `scripts/velero-crds`, which downloads the exact official chart archive,
  verifies its pinned SHA-256 digest, renders the matching bundled CRDs, and
  fails closed before apply unless both the exact release pair and Kubernetes
  context are supplied. The Helm CRD upgrade job remains disabled.
- Added `docs/runbooks/velero-upgrade.md` with separate CRD and Helm approvals,
  External Backup Store and repository-password preservation, complete per-hop
  observable exit gates, three fresh backup checks, stop behavior, and an
  explicit statement that restoreability remains unproven.
- `terraform fmt -check -recursive`, `git diff --check`, shell syntax checks,
  and both Terraform root validations passed. All four digest-pinned charts
  rendered exactly 13 Velero CRDs; the apply helper failed closed without its
  required confirmations. No Terraform plan/apply, CRD apply, Helm action,
  backup creation, restore, or other Live State mutation was performed.
- The required two-axis review reported no hard Standards violations and no
  Spec findings. Its sole judgment-call smell was deliberate duplication of the
  frozen release matrix across independently operated Terraform, safety-script,
  and human-runbook boundaries.
