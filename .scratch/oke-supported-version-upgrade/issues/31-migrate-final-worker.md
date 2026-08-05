# 31 — Migrate the final worker

**What to build:** Move PostgreSQL, Redis, Vaultwarden, and the remaining stateful workloads safely off the current `10.0.5.148` worker while keeping the old pool available until Migration Acceptance.

**Blocked by:** 30 — Migrate the second worker

**Status:** ready-for-human

- [ ] The live node identity and highest-risk placement rationale are re-resolved; a material mismatch pauses for reassessment.
- [ ] Current evidence remains valid and explicit human authorization is recorded before changing node or Longhorn scheduling state.
- [ ] Longhorn replica scheduling is disabled only on the selected node, which is cordoned and drained through eviction without forced deletion.
- [ ] Singleton and `ReadWriteOnce` interruptions are treated as accepted maintenance but never as permission to bypass a gate.
- [ ] All affected workloads recover on the new pool and every Longhorn volume returns to three healthy replicas with no pending operation.
- [ ] Argo, controllers, endpoints, ingress, Vaultwarden, Medusa, PostgreSQL, Redis, uploads, and other affected functional checks pass.
- [ ] The old Terraform pool entry and OCI pool remain intact; any failure uses the documented worker-only rollback branch.
