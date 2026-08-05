# 29 — Migrate the canary worker

**What to build:** Move workloads safely off the current `10.0.4.31` canary worker and prove the new pool through OpenVPN, Longhorn, platform, Argo, and functional behavior before another old worker is touched.

**Blocked by:** 28 — Create and qualify the v1.36.1 worker pool

**Status:** ready-for-human

- [ ] The live node identity and OpenVPN placement rationale are re-resolved; a material mismatch pauses for reassessment.
- [ ] Explicit human authorization is recorded before Longhorn scheduling or Kubernetes node state is changed.
- [ ] Longhorn replica scheduling is disabled only on the selected old node, which is then cordoned and drained through eviction without forced deletion.
- [ ] Evicted workloads and required platform replicas become ready on the new pool.
- [ ] Every Longhorn volume returns to three healthy replicas with no engine or replica on the drained node and no operation pending.
- [ ] Applications are Healthy/Synced, endpoints and Load Balancer backends are healthy, and OpenVPN connection/private reachability plus affected checks succeed.
- [ ] A failed trigger pauses further drains and follows the documented worker-only rollback branch while leaving the control plane on `v1.36.1`.
