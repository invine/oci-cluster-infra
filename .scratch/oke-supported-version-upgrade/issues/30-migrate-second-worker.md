# 30 — Migrate the second worker

**What to build:** Move workloads safely off the current `10.0.5.209` worker and prove Medusa, uploads, storage, platform, and Argo behavior before the highest-risk worker is touched.

**Blocked by:** 29 — Migrate the canary worker

**Status:** ready-for-human

- [ ] The live node identity and Medusa/uploads placement rationale are re-resolved; a material mismatch pauses for reassessment.
- [ ] Current migration evidence remains valid and explicit human authorization is recorded before changing node or Longhorn scheduling state.
- [ ] Longhorn replica scheduling is disabled only on the selected node, which is cordoned and drained through eviction without forced deletion.
- [ ] Evicted workloads and required platform replicas recover on the new pool.
- [ ] Every Longhorn volume returns to three healthy replicas with no pending operation or replica on the drained node.
- [ ] Applications, endpoints, ingress, Medusa storefront/backend, PostgreSQL, Redis, and uploads checks pass as applicable.
- [ ] A failed trigger stops the final drain and follows the documented worker-only rollback branch without control-plane downgrade.
