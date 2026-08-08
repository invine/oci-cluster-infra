# 29 — Migrate the canary worker

**What to build:** Move workloads safely off the current `10.0.4.31` canary worker and prove the `v1.36.1` Retained Worker Pool through OpenVPN, Longhorn, platform, Argo, and functional behavior before another old worker is touched.

**Blocked by:** 28 — Create and qualify the v1.36.1 worker pool

**Status:** resolved

- [x] The live node identity and OpenVPN placement rationale are re-resolved; a material mismatch pauses for reassessment.
- [x] Explicit human authorization is recorded before Longhorn scheduling or Kubernetes node state is changed.
- [x] Longhorn replica scheduling is disabled only on the selected old node, which is then cordoned and drained through eviction without forced deletion.
- [x] Evicted workloads and required platform replicas become ready on the `v1.36.1` Retained Worker Pool.
- [x] Every Longhorn volume returns to three healthy replicas with no engine or replica on the drained node and no operation pending.
- [ ] Applications are Healthy/Synced, endpoints and Load Balancer backends are healthy, and OpenVPN connection/private reachability plus affected checks succeed.
- [ ] A failed trigger pauses further drains and follows the documented worker-only rollback branch while leaving the control plane on `v1.36.1`.

## Answer

The revised Redis-and-Argo canary migration completed without forced deletion
or PDB bypass. `10.0.4.31` is cordoned and evacuated of ordinary pods and
Longhorn data placement; all workloads, platform controllers, endpoints, and
five three-replica volumes recovered. The recorded OpenVPN functional exception
remains for the final worker rather than being represented as a canary pass.

## Comments

- Gate 5 read-only re-resolution on 2026-08-08 confirmed that all three stored
  old-worker private IPs still identify Ready `v1.34.2` workers and that all
  three new workers are Ready on `v1.36.1`. Workload placement changed from the
  planning snapshot: `10.0.4.31` now hosts Medusa Redis and all Argo CD
  controller pods, while OpenVPN now runs on `10.0.5.148`. The stored address
  order can remain risk-ascending only with a new rationale: migrate
  `10.0.4.31` first to exercise one `ReadWriteOnce` Redis volume plus Argo
  recovery; migrate `10.0.5.209` second to exercise the uploads volume and
  Medusa backend/storefront; keep `10.0.5.148` last because it currently hosts
  OpenVPN, PostgreSQL, Vaultwarden, the Medusa worker, Velero, and three
  attached `ReadWriteOnce` volumes. This no longer proves OpenVPN during the
  canary drain and requires explicit Gate 5 risk-owner acceptance before any
  Longhorn scheduling or Kubernetes node-state mutation.
- The risk owner approved Gate 5 and the first-worker action after reviewing
  the revised placement and stated deviations. No old worker had been cordoned
  or drained before that approval.
- Migration ran from approximately `2026-08-08T07:43:49Z` through
  `2026-08-08T08:00:22Z`. Longhorn scheduling was disabled on only
  `10.0.4.31`; the Kubernetes node was cordoned and drained through eviction
  with DaemonSets ignored and no `--force` use. The Longhorn instance-manager
  PDB delayed drain completion and was respected rather than bypassed.
- Redis and all Argo CD controllers recovered on schedulable workers. Every
  active pod returned to Running, all workload controllers became fully ready,
  all five Argo Applications were Healthy/Synced, all declared HTTPS endpoints
  returned 200, Redis returned `PONG`, and PostgreSQL accepted connections.
- Longhorn's configured 600-second replenishment interval was allowed to
  elapse. Each of the five volumes rebuilt a replacement replica on new worker
  `10.0.6.191` and returned to attached/healthy with exactly three running
  replicas. Five stopped obsolete replica objects on `10.0.4.31` remained after
  replenishment; after re-verifying three healthy replacements per volume, the
  operator deleted only those exact stopped redundant replica objects. No
  Longhorn engine or replica remains on the drained worker, and only expected
  DaemonSet pods remain there.
- OpenVPN did not move during this canary because live placement had moved it
  to `10.0.5.148`. A credential-dependent tunnel/private-reachability test was
  therefore not repeated and the corresponding acceptance item remains
  unchecked under the Gate 5 deviation; the final-worker gate must still cover
  OpenVPN recovery.
