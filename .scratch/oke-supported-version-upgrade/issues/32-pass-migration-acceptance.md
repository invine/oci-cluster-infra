# 32 — Pass Migration Acceptance

**What to build:** Prove every workload, platform component, storage replica, endpoint, and backup is healthy on the `v1.36.1` Retained Worker Pool and record Approval Gate 6 before rollback capacity is weakened.

**Blocked by:** 31 — Migrate the final worker

**Status:** resolved

- [x] Every ordinary workload pod runs on the `v1.36.1` Retained Worker Pool; only expected DaemonSet pods remain on cordoned `v1.34.2` Retained Worker Pool workers.
- [x] No Longhorn engine or replica remains on a `v1.34.2` Retained Worker Pool worker, and all five volumes have three healthy `v1.36.1` Retained Worker Pool replicas with no pending operation.
- [x] All three `v1.36.1` Retained Worker Pool workers and required platform DaemonSets remain Ready.
- [x] Every Application is Healthy/Synced, every workload controller is fully available, and all endpoints and OCI Load Balancer backends are healthy.
- [x] OpenVPN, Vaultwarden, Echo, Medusa storefront/backend, PostgreSQL, Redis, uploads, and all declared HTTP/TLS checks pass.
- [x] New post-migration backups for all three stateful Application Namespaces complete with zero errors and warnings; repositories and Backup Storage Location remain healthy.
- [x] Approval Gate 6 binds explicit human approval to the complete evidence and identifies retirement of the `v1.34.2` Retained Worker Pool as the last rollback boundary.
- [x] A failed or changed condition leaves destruction protection and the `v1.34.2` Retained Worker Pool intact.

## Comments

- Migration Acceptance was evaluated on `2026-08-08` after ticket 31 resolved.
  All ordinary workload pods were on the three Ready `v1.36.1` Retained Worker
  Pool workers. The three `v1.34.2` Retained Worker Pool workers remained
  Ready, cordoned, and limited to expected DaemonSet pods.
- All five Longhorn volumes were attached and healthy with no pending node.
  Each volume had one running engine and exactly three running replicas, one on
  each `v1.36.1` Retained Worker Pool worker; no engine or replica remained on
  a `v1.34.2` Retained Worker Pool worker.
- All Deployments and StatefulSets were fully available, required DaemonSets
  were Ready, all five Argo CD Applications were Healthy/Synced at their
  recorded revisions, EndpointSlices were populated, and no Warning events
  were present. The OCI HTTP/TLS Load Balancer and OpenVPN Network Load
  Balancer both reported `OK` with no warning, critical, or unknown backend
  sets. Every declared HTTPS endpoint returned 200 with successful TLS
  verification.
- The operator confirmed Vaultwarden login works but reported that OpenVPN does
  not work and intends to repair it later. OpenVPN therefore fails a required
  Gate 6 functional check. The gate is paused: it is not approved, ticket 33
  remains blocked, and retirement of the `v1.34.2` Retained Worker Pool cannot
  begin while this condition remains failed.
- With explicit operator authorization, three post-migration backups were
  created: `gate6-staging-20260808t0927z`,
  `gate6-vaultwarden-20260808t0927z`, and
  `gate6-openvpn-20260808t0927z`. All completed with zero errors and warnings.
  The three Kopia repositories remained `Ready`, and the default Backup Storage
  Location remained `Available`.
- The private evidence snapshot is
  `/private/tmp/oke-worker-upgrade.4DfmAJ/gate6-acceptance-20260808T0927Z.txt`,
  mode `0600`, SHA-256
  `b1ba5b36bac45254d5e15c6d215447bdb5462480a3ba2b963dd2325d229c4065`.
  Both worker-pool Terraform state addresses remain present and the shared
  worker-pool resource still has `prevent_destroy = true`; no Infrastructure
  configuration, state, plan, or live worker-pool mutation was made.

## Answer

Migration Acceptance Gate 6 passed after the OpenVPN endpoint was repaired and
the operator confirmed the VPN was restored. All workloads, platform
components, storage replicas, endpoints, functional checks, and fresh
post-repair backups are healthy on the `v1.36.1` Retained Worker Pool. The
operator's instruction to resolve ticket 32 approves this evidence. Ticket 33
is now unblocked as the separate, reviewed retirement action; deleting the
`v1.34.2` Retained Worker Pool permanently removes worker rollback, while
restoreability remains unproven.

### Resolution evidence

- OpenVPN was repaired by publishing `everk8s-vpn.duckdns.org` to the dedicated
  Network Load Balancer at `132.145.20.152` and regenerating the published
  server/client configuration for that hostname. The replacement OpenVPN pod
  is Running/Ready with zero restarts on `10.0.7.40`; its EndpointSlice is
  populated, the OCI Network Load Balancer reports `OK`, and the regenerated
  published profile reached `Initialization Sequence Completed`. The operator
  then confirmed “openvpn is restored” and instructed “resolve ticket 32,”
  satisfying the human connection/private-reachability and Gate 6 approval
  records.
- The complete post-repair health refresh passed. All ordinary workloads remain
  on the three Ready `v1.36.1` workers; old workers remain Ready, cordoned, and
  Longhorn-unschedulable. Every controller is fully available, all five Argo CD
  Applications are Healthy/Synced, all five Longhorn volumes are healthy with
  three running replicas exclusively on the new workers, PostgreSQL returned
  `1`, Redis returned `PONG`, all declared HTTPS/TLS routes passed, Medusa
  `/health` returned 200, and both OCI load balancers report `OK`. The single
  OpenVPN `FailedAttachVolume` Warning is the resolved transient multi-attach
  wait from its controlled `Recreate` restart; current pod, endpoint, PVC, and
  volume state are healthy.
- Fresh post-repair backups
  `gate6-post-openvpn-staging-20260808t1205z`,
  `gate6-post-openvpn-vaultwarden-20260808t1205z`, and
  `gate6-post-openvpn-openvpn-20260808t1205z` all completed with zero errors and
  warnings. All five resulting PodVolumeBackups completed, all three Kopia
  repositories are `Ready`, and the default Backup Storage Location is
  `Available`.
- The final private evidence bundle is
  `/private/tmp/oke-worker-upgrade.4DfmAJ/gate6-acceptance-post-openvpn-20260808T1208Z.txt`,
  mode `0600`, SHA-256
  `c6821fa7a4329989c299f252d588a79095552f66feca2cb44481b3c55eca63c2`.
  The OpenVPN control log SHA-256 is
  `4d1b389fe578faf10e18d3815877e0f25486b198cfcfc8b08cdb3774c7907005`.
  Both worker-pool Terraform state addresses remain present and
  `prevent_destroy = true` remains in effect; ticket 32 made no old-pool,
  Terraform state, plan, or Infrastructure mutation.
