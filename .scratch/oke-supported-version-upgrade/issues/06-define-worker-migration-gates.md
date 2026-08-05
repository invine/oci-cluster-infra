# Define worker migration and rollback gates

Type: grilling
Status: resolved
Blocked by: 03, 04, 12

## Question

What exact cordon, drain, scheduling, Application Workload, ingress, storage, backup, and functional gates govern migration to the new worker pool, rollback to the retained `v1.34.2` pool, and irreversible old-pool removal under the Migration Acceptance Gate?

## Answer

Migrate exactly one old worker at a time. Keep the `v1.34.2` pool intact, cordoned as migration advances, until the full Migration Acceptance Gate passes. Application Workload interruptions are accepted, but every affected workload must recover and validate before the next old worker is touched.

### Gate before the first cordon

All of the following must pass:

- the OKE control plane is `ACTIVE` on `v1.36.1`;
- the new pool contains exactly three `Ready` workers on `v1.36.1`, using the exact approved OKE image and intended availability-domain placement;
- OCI CNI, kube-proxy, OCI CSI, Longhorn manager/CSI/engine-image, F5 NGINX Ingress, and Velero node-agent DaemonSets are ready on every new worker;
- every new Longhorn node and disk is ready, schedulable, and has sufficient capacity;
- all five Longhorn volumes and all replicas are healthy, with no rebuild, migration, attachment, or engine operation pending;
- all Argo CD Applications are `Healthy` and `Synced`, and all non-completed pods are ready without unexpected restarts or pending state;
- ingress addresses, TLS, Echo, OpenVPN, Vaultwarden, and Medusa baseline functional checks pass; and
- fresh Velero backups for `staging`, `vaultwarden`, and `openvpn` are `Completed` with zero errors and warnings, their Kopia BackupRepositories are `Ready`, and the Backup Storage Location is available.

### Old-worker order

Drain from lower to higher stateful risk:

1. `10.0.4.31` as the canary, exercising the OpenVPN `ReadWriteOnce` volume and UDP path.
2. `10.0.5.209`, exercising the Medusa backend and uploads volume.
3. `10.0.5.148` last, because it currently hosts PostgreSQL, Redis, Vaultwarden, and most stateful Application Workload pods.

Resolve the live node identities again immediately before execution and stop if they no longer match this recorded placement rationale.

### Per-worker migration gate

For only the selected old worker:

1. Disable Longhorn replica scheduling on that Longhorn node while leaving every other old node available for rollback.
2. Cordon the Kubernetes node.
3. Drain through the eviction API, respecting workload safety controls and ignoring DaemonSet pods. Do not use forced pod deletion; any object that cannot be safely evicted stops the step for inspection.
4. Wait for evicted workloads and required platform replicas to become ready on the new pool.
5. Require Longhorn to evacuate or rebuild the selected node's replicas so every volume returns to three healthy replicas, with no engine or replica remaining on the drained old node and no operation pending.
6. Require every Application to return to `Healthy` and `Synced`; require all affected pods ready; verify relevant Service endpoints and OCI Load Balancer backends point to ready pods.
7. Re-run the affected functional checks: HTTP/TLS for ingress applications, an OpenVPN connection and private reachability for OpenVPN, Vaultwarden login/read access, and Medusa storefront/backend plus PostgreSQL, Redis, and uploads behavior.

Only after all seven conditions pass may the next old worker begin migration.

### Failure and worker-only rollback

Any failed provisioning, readiness, eviction, scheduling, Longhorn, Argo, ingress, backup, or functional gate immediately pauses further drains. There is no elapsed-time trigger. Remediate and repeat the failed gate while both pools remain available.

Roll the affected workloads back when Longhorn becomes degraded or faulted, volume attachment/data access fails, the new workers are unstable, or an affected application cannot be returned to working health on the new pool:

1. stop all further old-worker drains;
2. cordon the new workers involved in the failed placement;
3. re-enable Longhorn replica scheduling on the retained old workers and uncordon the required old workers;
4. evict affected workloads from the new pool one node at a time without forced deletion;
5. wait for Longhorn detach/reattach and replica health on the old pool; and
6. require Applications `Healthy`/`Synced` plus storage, ingress, and functional checks before declaring worker rollback complete.

The OKE control plane remains on `v1.36.1`; it is never downgraded as part of worker rollback.

### Migration Acceptance Gate and old-pool removal

Before deleting the old pool, require all of the following simultaneously:

- every ordinary workload pod runs on the new pool; only expected DaemonSet pods may remain on cordoned old workers;
- no Longhorn volume engine or replica remains on any old worker;
- all three new workers and every required platform DaemonSet remain ready;
- all five Longhorn volumes have three healthy replicas on the new pool with no pending operation;
- every Argo CD Application is `Healthy` and `Synced`, and every workload controller is fully available;
- every declared HTTP/TLS endpoint works, OCI Load Balancer backends are healthy, OpenVPN connectivity works, Vaultwarden login/read access works, and Medusa storefront/backend, PostgreSQL, Redis, and uploads checks pass;
- new post-migration backups for `staging`, `vaultwarden`, and `openvpn` are `Completed` with zero errors and warnings; all Kopia repositories remain `Ready`; and
- the Backup Storage Location remains available.

Once this gate passes, remove the old pool immediately through Terraform. After OCI reports its deletion complete, repeat node, pod, DaemonSet, Longhorn, Argo, ingress, application, repository, and Backup Storage Location checks. Old-pool removal is irreversible within this plan; any later failure uses forward repair and the accepted backup posture rather than worker rollback.
