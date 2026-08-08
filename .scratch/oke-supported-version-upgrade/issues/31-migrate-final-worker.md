# 31 — Migrate the final worker

**What to build:** Move PostgreSQL, Redis, Vaultwarden, and the remaining stateful workloads safely off the current `10.0.5.148` worker while keeping the `v1.34.2` Retained Worker Pool available until Migration Acceptance.

**Blocked by:** 30 — Migrate the second worker

**Status:** resolved

- [x] The live node identity and highest-risk placement rationale are re-resolved; a material mismatch pauses for reassessment.
- [x] Current evidence remains valid and explicit human authorization is recorded before changing node or Longhorn scheduling state.
- [x] Longhorn replica scheduling is disabled only on the selected node, which is cordoned and drained through eviction without forced deletion.
- [x] Singleton and `ReadWriteOnce` interruptions are treated as accepted maintenance but never as permission to bypass a gate.
- [x] All affected workloads recover on the `v1.36.1` Retained Worker Pool and every Longhorn volume returns to three healthy replicas with no pending operation.
- [ ] Argo, controllers, endpoints, ingress, Vaultwarden, Medusa, PostgreSQL, Redis, uploads, and other affected functional checks pass.
- [x] The `v1.34.2` Retained Worker Pool's Terraform entry and OCI pool remain intact; any failure uses the documented worker-only rollback branch.

## Answer

The final old worker was migrated without forced deletion or PDB bypass. Every
ordinary workload, Longhorn engine, and replica now runs on the three
`v1.36.1` workers; all storage, Argo, controller, endpoint, database, and
persistent-data checks passed. The protected `v1.34.2` Retained Worker Pool
remains active and cordoned for rollback, while the accepted OpenVPN tunnel and
published-name exceptions remain recorded rather than being represented as
resolved.

## Comments

- The risk owner explicitly approved migration of both remaining workers after
  the canary completed and instructed the operator not to request another
  approval until both were migrated. Final-worker placement was re-resolved:
  `10.0.5.148` hosted OpenVPN, PostgreSQL, Vaultwarden, Medusa worker, Velero,
  and the OpenVPN, PostgreSQL, and Vaultwarden volume engines, preserving its
  highest-risk position.
- Migration ran from approximately `2026-08-08T08:07:00Z` through
  `2026-08-08T08:12:04Z`. Longhorn node and disk scheduling were disabled and
  replica eviction requested only on `10.0.5.148`; the node was cordoned and
  drained through eviction with DaemonSets ignored and without `--force`. The
  Longhorn instance-manager PDB was respected. The accepted singleton and
  `ReadWriteOnce` interruption posture did not bypass any exit gate.
- OpenVPN recovered on `10.0.6.191`; PostgreSQL and Vaultwarden recovered on
  `10.0.7.40`; the Medusa worker and Velero recovered on new workers. All five
  volumes became attached/healthy with exactly three running replicas on
  `10.0.6.191`, `10.0.7.40`, and `10.0.7.83`. No Longhorn engine or replica
  remains on any old worker and no pending node or failed replica was observed.
- All five Argo Applications were Healthy/Synced at the audited revisions,
  every workload controller was fully ready, no active pod was non-Running,
  and every declared HTTPS endpoint returned 200. PostgreSQL executed
  `SELECT 1`, Redis returned `PONG`, and Vaultwarden's migrated data volume
  passed a temporary write/read/delete probe. The earlier Medusa uploads probe
  remained valid after the final drain.
- The OpenVPN process is running, its Service retained public LoadBalancer
  address `132.145.20.152`, and its UDP/1194 EndpointSlice is Ready on
  `10.0.6.191`. A credential-dependent client tunnel/private-reachability test
  was not repeated and the published-name mismatch remains, so the broad
  functional-check item stays unchecked under the previously approved Gate 5
  deviation.
- OCI reports both three-node pools `ACTIVE`: retained `v1.34.2`
  `prod-cluster-pool-v134-8cde4f63` and retained `v1.36.1`
  `prod-cluster-pool-v136-20260808`. All three old Kubernetes nodes remain
  cordoned with only expected DaemonSet pods. Neither Terraform pool entry was
  removed, and worker-only rollback remains available pending Migration
  Acceptance.
- The final saved full Infrastructure plan reported no changes with SHA-256
  `79380155dc8f7041b313db30076b75b9e3c82265dde337ff6f920c6bac725df6`.
  It is mode `0600` beside the other worker-migration plans in the private
  evidence directory `/private/tmp/oke-worker-upgrade.4DfmAJ`.
