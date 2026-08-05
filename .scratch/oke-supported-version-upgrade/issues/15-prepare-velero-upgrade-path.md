# 15 — Prepare the Velero upgrade path

**What to build:** Prepare four coherent Velero upgrade sets so each live hop can advance the chart, server, node agent, restore helper, AWS plugin, and CRDs together while preserving backup access.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] The four chart/application/AWS-plugin sets are exactly `8.7.2/1.15.2/1.11.1`, `10.1.3/1.16.2/1.12.2`, `11.4.0/1.17.1/1.13.2`, and `12.1.0/1.18.1/1.14.2`.
- [ ] Matching server, node-agent, restore-helper, and plugin images are pinned as one coherent set per hop.
- [ ] Each hop has a reproducible mechanism to apply CRDs for that exact Velero minor before Helm while automatic CRD upgrades remain disabled.
- [ ] The External Backup Store remains external and neither Terraform state attempts to own it.
- [ ] Each hop defines exit checks for the Velero Deployment, node-agent DaemonSet, Backup Storage Location, Kopia BackupRepositories, and fresh backups for `staging`, `vaultwarden`, and `openvpn`.
- [ ] No restore rehearsal or claim of proven restoreability is added.
- [ ] Terraform formatting and non-mutating validation pass; no live backup, CRD, or release mutation is performed.
