# 30 — Migrate the second worker

**What to build:** Move workloads safely off the current `10.0.5.209` worker and prove Medusa, uploads, storage, platform, and Argo behavior before the highest-risk worker is touched.

**Blocked by:** 29 — Migrate the canary worker

**Status:** resolved

- [x] The live node identity and Medusa/uploads placement rationale are re-resolved; a material mismatch pauses for reassessment.
- [x] Current migration evidence remains valid and explicit human authorization is recorded before changing node or Longhorn scheduling state.
- [x] Longhorn replica scheduling is disabled only on the selected node, which is cordoned and drained through eviction without forced deletion.
- [x] Evicted workloads and required platform replicas recover on the `v1.36.1` Retained Worker Pool.
- [x] Every Longhorn volume returns to three healthy replicas with no pending operation or replica on the drained node.
- [x] Applications, endpoints, ingress, Medusa storefront/backend, PostgreSQL, Redis, and uploads checks pass as applicable.
- [x] A failed trigger stops the final drain and follows the documented worker-only rollback branch without control-plane downgrade.

## Answer

The second old worker was migrated without forced deletion or PDB bypass.
Medusa backend, storefront, and uploads recovered on the `v1.36.1` Retained
Worker Pool, all functional checks passed, all Longhorn placement left
`10.0.5.209`, and the node remains cordoned with only expected DaemonSets while
worker-only rollback capacity remains available.

## Comments

- After the canary gate passed, the risk owner explicitly approved serial
  migration of both remaining workers and directed the operator not to request
  another approval until both completed. Current placement still assigned the
  Medusa backend, storefront, and uploads engine to `10.0.5.209`.
- Migration ran from approximately `2026-08-08T08:02:00Z` through
  `2026-08-08T08:06:22Z`. Longhorn node and disk scheduling were disabled and
  replica eviction requested only on `10.0.5.209`; the node was cordoned and
  drained through eviction with DaemonSets ignored and without `--force`. The
  Longhorn instance-manager PDB was respected.
- All five volumes retained or returned to attached/healthy with exactly three
  running replicas. Replicas were evacuated to `10.0.6.191` and `10.0.7.40`;
  no replica or engine remained on `10.0.5.209`. Medusa uploads detached and
  reattached on `10.0.7.83`, and the replacement backend became ready there.
- The Medusa uploads filesystem passed a temporary write/read/delete probe.
  The Medusa API health endpoint and storefront returned HTTPS 200; every other
  declared HTTPS endpoint also returned 200. PostgreSQL accepted connections,
  Redis returned `PONG`, all five Argo Applications were Healthy/Synced, every
  workload controller was fully ready, and only expected DaemonSet pods
  remained on the drained node. No rollback trigger fired.
