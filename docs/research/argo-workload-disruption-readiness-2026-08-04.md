# Argo workload disruption readiness for Kubernetes 1.36.1

Date: 2026-08-04

## Conclusion

The exact desired state can now be identified, and it does **not** support the declared zero-Application-Workload-downtime migration objective as authored. Read-only live evidence reports all five Argo Applications `Synced` and `Healthy`, with these immutable revisions:

| Applications | Repository revision | Paths |
| --- | --- | --- |
| `argocd-bootstrap`, `echo-app`, `openvpn`, `vaultwarden` | `invine/k8s-charts@eec87a3274e2b753e66939d6b2786fb728d8fb05` | `argocd-bootstrap/root`, `echo-chart`, `openvpn-chart`, `vaultwarden-chart` |
| `medusa-staging` | `invine/my-medusa-store@06a825efd520771cd2c04500c10f0eb6b371aeaf` | `charts/medusa` with `values-staging.yaml` |

The exact commits were read from local Git objects without switching branches and rendered with Helm using the parameters/value file declared by the Argo Application manifests. No Secret payload was read. The blockers are workload architecture and disruption policy, not a removed built-in API:

- Every rendered workload has one replica. OpenVPN, Vaultwarden, and the Medusa backend explicitly use `Recreate`, so the old pod is terminated before the replacement is created. Medusa PostgreSQL and Redis are single-replica StatefulSets. Those five components necessarily have an interruption during eviction/recreation; their current shape cannot meet literal zero downtime.
- No rendered workload defines a PodDisruptionBudget. Kubernetes documents that PDBs limit simultaneous voluntary disruptions and that node drain uses the Eviction API; a PDB is necessary protection after workloads are made redundant, but cannot make a singleton highly available ([disruptions](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/), [safe node drain](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)).
- Echo has one replica with the default rolling strategy but no readiness, liveness, or startup probe. OpenVPN and Vaultwarden also have no probes. The Medusa backend and storefront, PostgreSQL, and Redis have readiness and liveness probes but no startup probes; the Medusa worker has none. Kubernetes removes a pod from matching Service endpoints when its readiness probe fails, so the missing readiness probes prevent a defensible availability gate ([Kubernetes probes](https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/)).
- Five volumes are Longhorn `ReadWriteOnce`: OpenVPN data, Vaultwarden data, Medusa backend uploads, PostgreSQL data, and Redis data. `ReadWriteOnce` permits read-write mounting by a single node; it does not prove prompt detach/reattach on a replacement node ([persistent-volume access modes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)). Static manifests therefore cannot clear storage mobility or establish a bounded interruption.
- No workload defines topology-spread constraints, pod anti-affinity, node selectors, or tolerations. Nothing statically pins these workloads away from the new pool, but there is also no placement policy protecting redundant replicas across failure domains if replicas are added.
- OpenVPN additionally binds UDP `hostPort: 1194`. This does not prevent placement on a different node, but only one such pod can use that node/port combination and its external UDP service must be exercised during a canary move.
- Vaultwarden renders an unexpected empty `spec` field inside its Deployment `spec`, alongside `strategy`. Remove this malformed field and validate the rendered object against the target API schema before upgrading; reliance on API-server pruning/lenient field validation is not an acceptable migration assumption.

## Kubernetes API audit

Rendered Application Workloads use stable built-in APIs: core `v1`, `apps/v1`, and `networking.k8s.io/v1`. Medusa migrations are disabled at this revision, so no `batch/v1` Job is rendered. The bootstrap graph also uses `argoproj.io/v1alpha1` Application/AppProject resources, and workload charts render `velero.io/v1` Schedules; these are extension APIs owned by installed CRDs, not built-in APIs removed by Kubernetes 1.36. No deprecated built-in API is visible in the exact source or rendered objects when compared with the official [Kubernetes deprecated API migration guide](https://kubernetes.io/docs/reference/using-api/deprecation-guide/).

This static result does not replace checking live API-request metrics or audit logs: controllers and clients can call deprecated endpoints that do not appear in manifests. Argo CD and Velero CRD/schema compatibility must also be cleared by their platform upgrades.

## Required disposition before worker migration

The planning decision must do one of the following:

1. Keep literal zero Application Workload downtime and change the workload architecture before draining: introduce application-appropriate redundancy/failover, readiness/startup probes, rolling strategies, PDBs, and placement rules; for PostgreSQL, Redis, and other RWO state, provide a tested HA/failover design rather than merely increasing replicas.
2. Explicitly relax the objective and approve bounded maintenance interruptions for the singleton stateful/Recreate workloads.

In either case, the runbook must still perform a controlled canary drain and capture live Longhorn volume health plus detach/reattach timings. Acceptance requires all Applications to return `Synced` and `Healthy`, all workload readiness and functional checks to pass, ingress/OpenVPN paths to work, and storage to be healthy. Those runtime canary and live-storage checks remain open evidence gaps; static source cannot prove them.

## Method and scope

- Examined only `invine/k8s-charts@eec87a3274e2b753e66939d6b2786fb728d8fb05` and `invine/my-medusa-store@06a825efd520771cd2c04500c10f0eb6b371aeaf` from existing local Git object databases.
- Rendered Echo, OpenVPN, and Vaultwarden with the Helm parameter overrides in their Application manifests; rendered Medusa with `values-staging.yaml`.
- Inspected replicas, rollout strategy, probes, PDBs, scheduling constraints, `hostPort`, PVC access modes/storage classes, and API versions.
- Made no Kubernetes, Argo CD, OCI, Terraform, or Git mutation.
