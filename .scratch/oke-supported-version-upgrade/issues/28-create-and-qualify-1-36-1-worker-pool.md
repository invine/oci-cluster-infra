# 28 — Create and qualify the v1.36.1 worker pool

**What to build:** Create three paid `v1.36.1` workers beside the protected old pool, prove the new pool can host the platform and Application Workloads, and record Approval Gate 5 before migration.

**Blocked by:** 27 — Upgrade the control plane to v1.36.1

**Status:** ready-for-human

- [ ] The pinned image is re-queried and exactly matches Kubernetes `v1.36.1` and the approved Oracle Linux family.
- [ ] The full plan creates only the new three-node pool and does not alter, replace, or destroy the old pool.
- [ ] Explicit human authorization is recorded before the pool-creation apply.
- [ ] All three new workers are Ready with the intended availability-domain placement.
- [ ] OCI CNI, kube-proxy, OCI CSI, Longhorn, F5 NGINX, and Velero DaemonSets are ready on every new worker.
- [ ] Longhorn nodes/disks have sufficient capacity, all five volumes and replicas are healthy, and no storage operation is pending.
- [ ] Argo, pods, ingress, TLS, Echo, OpenVPN, Vaultwarden, Medusa, fresh backups, repositories, and Backup Storage Location pass the full pre-cordon gate.
- [ ] Approval Gate 5 binds migration authorization to this exact evidence; a failed check leaves all old workers untouched.
