# 34 — Close and hand off the upgrade

**What to build:** Produce the final auditable record of the completed production upgrade and hand its residual risks and operating state to the cluster owner.

**Blocked by:** 33 — Retire the v1.34.2 worker pool

**Status:** resolved

- [x] Final control-plane version, worker versions, approved image OCIDs, and Shared Platform Service pins are recorded.
- [x] Reviewed plans, applies, OCI work requests, state migration, node migrations, functional results, backups, and all six approvals are linked or recorded without exposing sensitive values.
- [x] Post-deletion verification is complete and the runbook has no unresolved failed gate.
- [x] Residual risks explicitly state that restoreability was not rehearsed, Application Workloads remain singleton/non-HA where identified, and worker rollback is unavailable.
- [x] Local Sensitive Artifacts remain untracked and retain restrictive permissions.
- [x] The upgrade is declared complete only when the evidence package has a named owner; otherwise it remains paused with a recorded next action.

## Comments

- Handoff preparation began on `2026-08-08` after the authorized old-pool
  deletion completed. Final observed infrastructure is an `ACTIVE` Kubernetes
  `v1.36.1` control plane and one three-node `v1.36.1` Retained Worker Pool,
  `prod-cluster-pool-v136-20260808`, pinned to
  `Oracle-Linux-8.10-aarch64-2026.07.20-0-OKE-1.36.1-1578` at image OCID
  `ocid1.image.oc1.uk-london-1.aaaaaaaaxjzrb6kfoac2nsi5hv4oigqynuwwr4xm5yzflrxlsql6l3cqmb3a`.
  The final Shared Platform Service pins are Longhorn `1.12.0`, Velero
  chart/application/AWS plugin `12.1.0/1.18.1/1.14.2`, cert-manager `v1.21.1`,
  F5 NGINX chart/application `2.6.4/5.5.4`, and Argo CD chart/application
  `10.2.3/3.5.0`.
- The post-deletion automated node, pod, controller, Longhorn, Argo, ingress,
  EndpointSlice, HTTP/TLS, PostgreSQL, Redis, OCI load-balancer, repository,
  Backup Storage Location, Infrastructure State, and full-plan checks pass.
  The human operator confirmed OpenVPN connection/private reachability,
  Vaultwarden login/item read, and Medusa persisted upload/read behavior, so
  ticket 33 is resolved.
- Approval Gate 2 in ticket 25 also remains historically unresolved. The later
  OpenVPN repair removes its live endpoint blocker, but it does not
  retroactively supply exact-artifact-bound authorization or the missing
  contemporaneous per-release upgrade-note evidence. A human risk-owner
  disposition was required before this handoff could state that no approval
  gate remained unresolved. The human risk owner subsequently accepted both
  historical deviations, and ticket 25 is resolved with the unmet controls
  preserved in its record rather than rewritten as satisfied.
- The requesting human explicitly accepted ownership of the final evidence
  package. The named receiving operational role is **Cluster Owner**. With
  tickets 25 and 33 resolved, no approval gate or upgrade ticket remains open.

## Final handoff

### Operating state

- OCI reports `prod-cluster` `ACTIVE` on exact Kubernetes `v1.36.1`.
- OCI reports only `prod-cluster-pool-v136-20260808`, `ACTIVE` with three
  `ACTIVE` nodes (`10.0.6.191`, `10.0.7.40`, and `10.0.7.83`) on exact
  Kubernetes `v1.36.1`. The pool is pinned to image
  `Oracle-Linux-8.10-aarch64-2026.07.20-0-OKE-1.36.1-1578`, OCID
  `ocid1.image.oc1.uk-london-1.aaaaaaaaxjzrb6kfoac2nsi5hv4oigqynuwwr4xm5yzflrxlsql6l3cqmb3a`.
- Deployed Shared Platform Service pins are Longhorn chart/application
  `1.12.0/v1.12.0`, Velero chart/application/AWS plugin
  `12.1.0/1.18.1/1.14.2`, cert-manager chart/application `v1.21.1/v1.21.1`,
  F5 NGINX chart/application `2.6.4/5.5.4`, and Argo CD chart/application
  `10.2.3/v3.5.0`.
- Argo Applications `argocd-bootstrap`, `echo-app`, `openvpn`, and
  `vaultwarden` are Healthy/Synced at
  `k8s-charts@eec87a3274e2b753e66939d6b2786fb728d8fb05`;
  `medusa-staging` is Healthy/Synced at
  `my-medusa-store@06a825efd520771cd2c04500c10f0eb6b371aeaf`.

### Approval and execution index

| Gate/phase | Durable record | Final disposition |
| --- | --- | --- |
| Gate 1 — Starting Baseline | [Ticket 20](issues/20-pass-starting-gate-and-migrate-pool-state-address.md) | Exact validated state-address/security-rule/kubeconfig plan `6cecfbe7759d60dcfc25ff0530d1a87b498d429699f0730805e8f55ccdaf508f` applied; follow-up plan `7229e41b07b3db2a76c11d692e544db9f1dbf3421c499790774993827b23fbf9` empty; risk owner accepted the recorded approval-timing deviation. |
| Platform upgrades | [Longhorn](issues/21-upgrade-longhorn-to-1-12-0.md), [Velero](issues/22-upgrade-velero-to-1-18-1.md), [cert-manager](issues/23-upgrade-cert-manager-to-1-21-1.md), [F5 NGINX](issues/24-upgrade-f5-nginx-to-5-5-4.md), [Argo CD](issues/25-upgrade-argo-cd-and-approve-platform-completion.md) | Every frozen hop, CRD artifact, saved-plan checksum, recovery, final pin, and accepted deviation is retained in its ticket. |
| Gate 2 — Platform Complete | [Ticket 25](issues/25-upgrade-argo-cd-and-approve-platform-completion.md) | Final full Platform plan `6052a15f1a0fa1a5849ca2c09c5889ce53014c5c6bda91c00480926661a3938e` empty; later OpenVPN repair passed; risk owner explicitly accepted prospective authorization and incomplete contemporaneous upgrade-note evidence. |
| Gate 3 — v1.35.2 | [Ticket 26](issues/26-upgrade-control-plane-to-1-35-2.md) | Plan `74f98c8556622fc4f84d35824ff85188525460f8484ea6be8c15043e045d40fd` applied; OCI work request `ocid1.clustersworkrequest.oc1.uk-london-1.amaaaaaa7dbnwvaal4hw6cueeitgpqo7iiqd3sweztlnjsce7ajeofjyo6sa` succeeded; risk owner accepted recorded control deviations. |
| Gate 4 — v1.36.1 | [Ticket 27](issues/27-upgrade-control-plane-to-1-36-1.md) | Plan `2927223e1051a46b1c84e80c34d9ea1aaa1ecacb316648c7e5c8c6649adb4641` applied; OCI work request `ocid1.clustersworkrequest.oc1.uk-london-1.amaaaaaa7dbnwvaamddl42qbgxwe3zjiziwnfhi6oo2tnatb5s65jo3neaha` succeeded; follow-up plan `851a8ff5ae94fba663f22c7c6dcdd1fad97179d93fd4a1a840364a0196553e65` empty; risk owner accepted recorded control deviations. |
| Gate 5 — Worker migration | [Pool qualification](issues/28-create-and-qualify-1-36-1-worker-pool.md), [canary](issues/29-migrate-canary-worker.md), [second worker](issues/30-migrate-second-worker.md), [final worker](issues/31-migrate-final-worker.md) | Creation plan `c9dbbb92eeb3ee8175c7d086de1e0ef9596b5a3ba102684eca6dfd1ee9ba9cd4` and OCI work request `ocid1.clustersworkrequest.oc1.uk-london-1.aaaaaaaajs33eifr72tksgzhph7kohht3y3uxdosr4hhbvcrdwetwluhd2ba` succeeded; retained-disposition plan `627ce34f6ae72bc8afdb8a416f05511c5f9e7973a6a5f49bfdd85e19cb72a91f` empty; all three workers migrated serially without forced deletion or PDB bypass. |
| Gate 6 — Migration Acceptance | [Ticket 32](issues/32-pass-migration-acceptance.md) | Complete repaired-endpoint evidence SHA-256 `c6821fa7a4329989c299f252d588a79095552f66feca2cb44481b3c55eca63c2`; all functional and fresh-backup checks passed; risk owner approved the final rollback boundary. |
| Old-pool retirement | [Ticket 33](issues/33-retire-1-34-2-worker-pool.md) | No-change protection-removal plan `b4a8791567ca5edc946f5d9580591f5e49e3e4dc5c8f6c4f18a923150afca312` and destruction-only plan `b13401ddd68389637276d0d607f174df96eaa75a395be9836eb10bad1f0ef0bb` were separately reviewed and authorized; OCI deletion work request `ocid1.clustersworkrequest.oc1.uk-london-1.amaaaaaa7dbnwvaar23griq47qbe6ykin6qqvofvjqmptmq2ypsyxpvmakga` succeeded; final plan `fa3232b82e162b736bee6695a2f8493df17f846230f7220e12cee29cb2545524` empty. |

Fresh backup identifiers and timestamps are retained in tickets 20, 22, 25,
28, and 32. The final Gate 6 set is
`gate6-post-openvpn-{staging,vaultwarden,openvpn}-20260808t1205z`; each backup
Completed with zero errors and warnings, all five PodVolumeBackups Completed,
all three Kopia repositories are Ready, and the Backup Storage Location is
Available. This proves current backup creation and External Backup Store
access, not restoreability.

### Post-deletion acceptance

Exactly three Ready `v1.36.1` nodes remain. All active pods and workload
controllers are ready. Longhorn contains only the three retained workers; its
five volumes are attached and healthy with fifteen replicas exclusively on
those workers. All five Argo Applications are Healthy/Synced, every service
EndpointSlice has a Ready endpoint, HTTP/TLS checks pass, PostgreSQL returns
`1`, Redis returns `PONG`, both OCI load balancers report `OK`, and the human
operator confirmed OpenVPN private reachability, Vaultwarden login/item read,
and Medusa persisted upload/read. Infrastructure State contains only the
`v1.36.1` worker pool and the final full plan is empty.

### Evidence custody and residual risks

The durable non-sensitive index is this ticket and its linked issues. Private
evidence remains under mode-`0700` directories including
`/private/tmp/oke-gate1-20260807.mW1XTL`,
`/private/tmp/oke-cp-upgrade.2AXnmt`, and
`/private/tmp/oke-worker-upgrade.4DfmAJ`; saved plans and evidence files are
mode `0600`. Real tfvars remain Git-ignored, untracked, and mode `0600`. The
named receiving owner is the **Cluster Owner**, explicitly accepted by the
requesting human.

Residual risks accepted at handoff:

- restoreability remains unproven because no Velero/Kopia or Longhorn restore
  rehearsal was performed;
- Application Workloads remain singleton/non-HA where identified, with the
  accepted bounded-interruption posture and `ReadWriteOnce` storage;
- the `v1.34.2` pool is deleted, so worker-only rollback is unavailable and all
  later failures require supported forward repair plus the accepted backup
  posture; and
- the historical approval-timing, exact-artifact binding, upgrade-note,
  Longhorn backup, per-volume audit, and explicit data-path evidence deviations
  remain recorded in their source tickets rather than being retroactively
  represented as satisfied.

## Answer

The production OKE upgrade is complete and handed to the Cluster Owner. The
cluster and sole three-node worker pool are `ACTIVE` on exact Kubernetes
`v1.36.1`; every Shared Platform Service is on its frozen final pin; all six
approval gates and the guarded old-pool retirement are closed; final automated
and human functional checks pass; and Terraform is converged with an empty full
Infrastructure plan. The Cluster Owner accepts the recorded residual risks,
including unproven restoreability, singleton/non-HA Application Workloads, and
the permanent loss of worker-only rollback.
