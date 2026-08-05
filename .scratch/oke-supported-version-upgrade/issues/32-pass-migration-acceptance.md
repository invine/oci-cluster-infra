# 32 — Pass Migration Acceptance

**What to build:** Prove every workload, platform component, storage replica, endpoint, and backup is healthy on the new workers and record Approval Gate 6 before rollback capacity is weakened.

**Blocked by:** 31 — Migrate the final worker

**Status:** ready-for-human

- [ ] Every ordinary workload pod runs on the new pool; only expected DaemonSet pods remain on cordoned old workers.
- [ ] No Longhorn engine or replica remains on an old worker, and all five volumes have three healthy new-pool replicas with no pending operation.
- [ ] All three new workers and required platform DaemonSets remain Ready.
- [ ] Every Application is Healthy/Synced, every workload controller is fully available, and all endpoints and OCI Load Balancer backends are healthy.
- [ ] OpenVPN, Vaultwarden, Echo, Medusa storefront/backend, PostgreSQL, Redis, uploads, and all declared HTTP/TLS checks pass.
- [ ] New post-migration backups for all three stateful Application Namespaces complete with zero errors and warnings; repositories and Backup Storage Location remain healthy.
- [ ] Approval Gate 6 binds explicit human approval to the complete evidence and identifies old-pool retirement as the last rollback boundary.
- [ ] A failed or changed condition leaves destruction protection and the old pool intact.
