# 22 — Upgrade Velero to 1.18.1

**What to build:** Move production Velero through each approved coherent release set to application `1.18.1` while proving current backup creation and External Backup Store access after every hop.

**Blocked by:** 21 — Upgrade Longhorn to 1.12.0

**Status:** ready-for-human

- [ ] Each CRD and Helm hop has a separately reviewed full plan and explicit human authorization.
- [ ] The four approved chart/application/AWS-plugin sets are applied in order without combining or substituting versions.
- [ ] Exact-minor CRDs are applied before their corresponding Helm hop while automatic CRD upgrades remain disabled.
- [ ] Server, node agent, restore helper, AWS plugin, and chart remain a matching set at every hop.
- [ ] After each hop, the Deployment and node-agent DaemonSet are ready, the Backup Storage Location is available, and all Kopia BackupRepositories are Ready.
- [ ] Fresh backups for `staging`, `vaultwarden`, and `openvpn` complete with zero errors and warnings after each hop.
- [ ] No restore rehearsal occurs and no evidence claims proven restoreability.
- [ ] Any failed backup, repository, CRD, rollout, or unrelated-plan check pauses progression.
