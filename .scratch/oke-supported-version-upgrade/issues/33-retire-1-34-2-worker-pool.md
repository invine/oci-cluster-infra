# 33 — Retire the v1.34.2 worker pool

**What to build:** Cross the final rollback boundary through two reviewed Terraform changes, delete only the old pool, and prove the remaining production cluster is healthy.

**Blocked by:** 32 — Pass Migration Acceptance

**Status:** resolved

- [x] Approval Gate 6 evidence is still current before any lifecycle protection is weakened.
- [x] The first reviewed change removes destruction protection while retaining both map entries, and its full plan shows no infrastructure changes.
- [x] The second reviewed change removes only the `v1.34.2` entry, and its fresh full plan shows destruction of only the old pool.
- [x] Explicit human authorization is obtained for the exact destruction plan immediately before apply.
- [x] OCI reports deletion complete and the old Kubernetes nodes disappear.
- [x] Node, pod, DaemonSet, Longhorn, Argo, ingress, Application Workload, repository, Backup Storage Location, and functional checks pass after deletion.
- [x] The evidence states that worker rollback is no longer available and subsequent failures use forward repair and the accepted backup posture.

## Comments

- On `2026-08-08`, the Gate 6 evidence artifact remained mode `0600` with its
  recorded SHA-256
  `c6821fa7a4329989c299f252d588a79095552f66feca2cb44481b3c55eca63c2`.
  A fresh read-only gate confirmed three Ready, cordoned `v1.34.2` workers,
  three Ready, schedulable `v1.36.1` workers, healthy workloads and
  controllers, five Healthy/Synced Argo Applications, five attached and
  healthy three-replica Longhorn volumes on the new workers, three Completed
  post-repair backups, three Ready Kopia repositories, and an Available Backup
  Storage Location.
- The first reviewed change removed only `prevent_destroy` while both worker
  entries remained configured. The saved full plan was mode `0600`, reported
  `No changes`, and had SHA-256
  `b4a8791567ca5edc946f5d9580591f5e49e3e4dc5c8f6c4f18a923150afca312`.
  The human explicitly authorized that exact artifact. Terraform applied it
  with `0 added, 0 changed, 0 destroyed`; the mandatory follow-up full plan
  was empty with SHA-256
  `a7e0027fea4359fe5328897ea62344e2b6b787b779cf9874a6898c4efdfcf828`.
- The second reviewed change removed only the private `v1.34.2` worker overlay
  entry. Machine inspection of the fresh full plan found exactly one action:
  delete `oci_containerengine_node_pool.worker_pool["v1.34.2"]`; there were
  no additions, updates, output changes, or unrelated actions. The mode-`0600`
  saved plan had SHA-256
  `b13401ddd68389637276d0d607f174df96eaa75a395be9836eb10bad1f0ef0bb`.
- Immediately after the human explicitly authorized that exact destruction
  artifact, the checksum was revalidated and Terraform applied it. OCI work
  request
  `ocid1.clustersworkrequest.oc1.uk-london-1.amaaaaaa7dbnwvaar23griq47qbe6ykin6qqvofvjqmptmq2ypsyxpvmakga`
  performed `NODEPOOL_DELETE` from `2026-08-08T12:20:54Z` through
  `2026-08-08T12:22:59Z` and finished `SUCCEEDED`. Terraform reported
  `0 added, 0 changed, 1 destroyed`.
- Post-deletion automation confirms exactly three Ready, schedulable
  `v1.36.1` nodes and only the `v1.36.1` pool in Infrastructure State. All 68
  active pods and all 38 Deployments, StatefulSets, and DaemonSets were ready.
  Longhorn retained exactly the three new nodes; all five volumes were attached
  and healthy with fifteen replicas exclusively on them. All five Argo
  Applications were Healthy/Synced, all 22 service EndpointSlices had Ready
  endpoints, the three Kopia repositories were Ready, and the Backup Storage
  Location was Available. HTTP/TLS checks passed for Argo CD, Echo, Medusa API
  health, Medusa storefront after its expected locale redirect, and
  Vaultwarden; PostgreSQL returned `1`, Redis returned `PONG`, and both OCI
  load balancers reported `OK`. The final full Infrastructure plan reported
  `No changes` with SHA-256
  `fa3232b82e162b736bee6695a2f8493df17f846230f7220e12cee29cb2545524`.
- The credential-dependent post-deletion OpenVPN connection/private-reachability,
  Vaultwarden login/item-read, and Medusa persisted upload/read checks still
  require human confirmation. Until they are recorded, this ticket remains
  open and ticket 34 cannot declare the upgrade complete. Worker rollback is
  already unavailable; any failure now follows supported forward repair and
  the accepted backup posture. Restoreability remains unproven.
- The human operator subsequently confirmed all three credential-dependent
  ticket 33 checks: OpenVPN connection/private reachability, Vaultwarden
  login/item read, and Medusa persisted upload/read. This completes the
  post-deletion functional gate without changing the already-recorded
  automated evidence.

## Answer

The protected `v1.34.2` Retained Worker Pool was retired through the required
two reviewed changes and exact-artifact authorizations. OCI completed deletion,
the three old Kubernetes and Longhorn nodes disappeared, only the healthy
three-node `v1.36.1` Retained Worker Pool remains, the final full Infrastructure
plan is empty, and all automated and human functional checks pass. Worker
rollback is permanently unavailable; subsequent failures use supported forward
repair and the accepted backup posture. Successful backups prove current backup
creation, but restoreability remains unproven because no restore rehearsal was
performed.
