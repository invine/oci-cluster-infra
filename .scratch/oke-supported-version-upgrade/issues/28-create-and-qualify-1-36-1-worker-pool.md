# 28 — Create and qualify the v1.36.1 worker pool

**What to build:** Create three paid `v1.36.1` workers beside the protected `v1.34.2` Retained Worker Pool, prove the Candidate Worker Pool can host the platform and Application Workloads, and record Approval Gate 5 before migration.

**Blocked by:** 27 — Upgrade the control plane to v1.36.1

**Status:** resolved

- [x] The pinned image is re-queried and exactly matches Kubernetes `v1.36.1` and the approved Oracle Linux family.
- [x] The full plan creates only the three-node Candidate Worker Pool and does not alter, replace, or destroy the `v1.34.2` Retained Worker Pool.
- [x] Explicit human authorization is recorded before the pool-creation apply.
- [x] All three new workers are Ready with the intended availability-domain placement.
- [x] OCI CNI, kube-proxy, OCI CSI, Longhorn, F5 NGINX, and Velero DaemonSets are ready on every new worker.
- [x] Longhorn nodes/disks have sufficient capacity, all five volumes and replicas are healthy, and no storage operation is pending.
- [ ] Argo, pods, ingress, TLS, Echo, OpenVPN, Vaultwarden, Medusa, fresh backups, repositories, and Backup Storage Location pass the full pre-cordon gate.
- [x] Approval Gate 5 binds migration authorization to this exact evidence; a failed check leaves all old workers untouched.

## Answer

The exact pinned `v1.36.1` Retained Worker Pool is active, represented in
Infrastructure State, qualified across node, DaemonSet, Longhorn, Argo,
ingress, endpoint, and fresh backup evidence, and locally classified as
retained behind an empty full plan. Gate 5 approval accepts the recorded
functional-check exceptions and revised live placement, so serial worker
migration may begin while the protected `v1.34.2` Retained Worker Pool remains
available for worker-only rollback.

## Comments

- On 2026-08-08 the operator re-queried OCI's regional worker-image catalog and
  pinned exact image
  `Oracle-Linux-8.10-aarch64-2026.07.20-0-OKE-1.36.1-1578`
  (`ocid1.image.oc1.uk-london-1.aaaaaaaaxjzrb6kfoac2nsi5hv4oigqynuwwr4xm5yzflrxlsql6l3cqmb3a`).
  The saved full creation plan had SHA-256
  `c9dbbb92eeb3ee8175c7d086de1e0ef9596b5a3ba102684eca6dfd1ee9ba9cd4`
  and contained exactly one add, the three-node `v1.36.1` Candidate Worker
  Pool; it contained zero changes and zero destroys. The retained `v1.34.2`
  pool had no action.
- The human authorized implementation of tickets 27-31 and instructed the
  operator to ask for approval only immediately before Application Workloads
  begin migrating from old workers to new workers. That instruction explicitly
  authorized pool creation without a separate action pause. OCI work request
  `ocid1.clustersworkrequest.oc1.uk-london-1.aaaaaaaajs33eifr72tksgzhph7kohht3y3uxdosr4hhbvcrdwetwluhd2ba`
  ran from `2026-08-08T07:17:41Z` to `2026-08-08T07:21:14Z` and succeeded.
- OCI reports pool
  `ocid1.nodepool.oc1.uk-london-1.aaaaaaaasvxd7oyjwk3b32ebbz3hgdyve65m5dip76russxamn3e64qgzdia`
  `ACTIVE` with three `ACTIVE` nodes placed one per London availability domain.
  Kubernetes reports `10.0.6.191`, `10.0.7.40`, and `10.0.7.83` Ready on exact
  `v1.36.1`. OCI CNI, kube-proxy, OCI CSI, Longhorn manager/CSI/engine-image,
  F5 NGINX, and Velero node-agent DaemonSets are 6/6 Ready.
- All six Longhorn nodes and disks are Ready and schedulable. Each new disk had
  approximately 25 GB available at qualification. All five volumes remained
  attached and healthy with three running replicas, no pending node, and no
  failed replica. All active pods were Running, all workload controllers were
  fully available, and all five Argo Applications were Healthy/Synced at the
  audited revisions.
- HTTP redirected to HTTPS for every declared ingress. Argo CD, Echo, and
  Vaultwarden returned HTTPS 200; the Medusa storefront returned 200 after its
  expected locale redirect; the Medusa API health endpoint returned 200 and
  its root retained the expected 404. Ingress retained address
  `130.162.161.246`; the OpenVPN LoadBalancer retained public address
  `132.145.20.152` and a ready endpoint.
- Fresh Gate 5 backups
  `gate5-staging-20260808t0730z`, `gate5-openvpn-20260808t0730z`, and
  `gate5-vaultwarden-20260808t0730z` completed with zero errors and warnings.
  The Backup Storage Location was Available and all three Kopia repositories
  were Ready.
- Qualification did not repeat credential-dependent Vaultwarden login/read,
  Medusa upload read/write, or an OpenVPN tunnel/private-reachability test. The
  pre-existing OpenVPN published-name mismatch also remains. The complete
  functional-gate item therefore remains unchecked pending the risk owner's
  Gate 5 disposition.
- After qualification, the `v1.36.1` pool's local disposition changed from
  `candidate` to `retained`. The saved full Infrastructure plan reported no
  changes and has SHA-256
  `627ce34f6ae72bc8afdb8a416f05511c5f9e7973a6a5f49bfdd85e19cb72a91f`.
  Both plans are mode `0600` under the private mode-`0700` directory
  `/private/tmp/oke-worker-upgrade.4DfmAJ`.
- The risk owner approved Gate 5 after reviewing the qualified `v1.36.1` pool, the fresh
  backup evidence, the revised live worker order, the credential-dependent
  functional-check gaps, and the pre-existing OpenVPN published-name mismatch.
  The approval explicitly authorizes migration to begin with `10.0.4.31` under
  the revised Redis-and-Argo canary rationale. The incomplete full functional
  item remains unchecked so the accepted deviation is not rewritten as a pass.
