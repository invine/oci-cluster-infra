# 20 — Pass the starting gate and migrate the pool state address

**What to build:** Establish the complete production baseline, record Approval Gate 1, and apply only the declarative Infrastructure State address move that preserves the existing `v1.34.2` worker pool.

**Blocked by:** 19 — Publish and validate the operator package

**Status:** ready-for-human

- [ ] No command that mutates Infrastructure State or Live State runs until the human approves the exact starting evidence and saved full plan.
- [ ] The baseline proves the cluster, existing workers, APIs/admission components, Shared Platform Services, Longhorn storage, Argo Applications, ingress, Application Workloads, backups, repositories, and Backup Storage Location satisfy Approval Gate 1.
- [ ] OCI still offers exact next hop `v1.35.2`, and current OKE skew rules permit the approved retained-worker sequence.
- [ ] Fresh backups for `staging`, `vaultwarden`, and `openvpn` are recorded as `Completed` with zero errors and warnings; restoreability is explicitly recorded as unproven.
- [ ] The approved full Infrastructure plan shows only preservation through the intended state-address move and no OCI resource creation, update, replacement, or destruction.
- [ ] After the authorized apply, a second full plan reports no changes.
- [ ] Any unexpected drift or plan effect pauses the ticket without applying or using `terraform -target`.
