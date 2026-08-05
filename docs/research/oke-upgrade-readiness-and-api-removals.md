# OKE upgrade readiness and API-removal audit

Research date: 2026-08-04

## Conclusion

The cluster is **not yet approved as upgrade-ready**. Repository configuration supports a blue/green worker-pool migration, but live evidence needed to protect the zero-Application-Workload-downtime promise could not be collected: the sandbox blocked the Kubernetes API endpoint and the subsequent read-only access request was not approved. This is an evidence gap, not a finding that the cluster is unhealthy.

The repository itself exposes four material gates:

1. The target Kubernetes version and matching OKE image must be proven available before planning an apply. The node-image selector silently falls back to the first OCI source when no image name matches the requested version (`local.oke_latest_image_id` in `infra/node-pool.tf`). That fallback can produce a non-matching or unintended worker image instead of failing closed.
2. The Argo-managed workload manifests are held in the external `invine/k8s-charts` repository, not this repository (`platform/argocd.tf`). No conclusion about removed APIs, PodDisruptionBudgets, replica counts, topology constraints, probes, or disruption tolerance is possible until the exact reconciled revision is scanned and compared with discovery data from the target API server.
3. Longhorn is configured for three replicas, hard replica anti-affinity, and no degraded volume creation (`platform/longhorn.tf`). A drain can therefore block or temporarily reduce storage resilience unless all three new nodes are ready, Longhorn-schedulable, and provide adequate disks before any old node is cordoned. Longhorn's official maintenance procedure requires checking volume health and choosing an appropriate node-drain policy before draining ([Longhorn node maintenance](https://longhorn.io/docs/1.7.2/maintenance/maintenance/)).
4. Velero uses file-system backup through node agents, has volume snapshots disabled, and disables Helm-managed CRD upgrades (`deployNodeAgent: true`, `snapshotsEnabled: false`, `upgradeCRDs: false` in `platform/velero.tf`). A successful recent backup cannot be inferred from this configuration; backup storage availability, backup completion, repository health, and an actual representative restore must all pass. Velero documents that file-system backups operate through node-agent pods and require explicit volume selection or defaulting ([Velero file-system backup](https://velero.io/docs/v1.14/file-system-backup/)).

## API and admission audit

The Terraform-authored Kubernetes resources use stable core `v1`, `cert-manager.io/v1`, and `networking.k8s.io` resources rendered by charts. The one `argoproj.io/v1alpha1` object is an Argo CD CRD version, not a deprecated built-in Kubernetes API. No built-in API already known to be removed is directly authored in the visible Terraform.

That is not a complete removed-API clearance. Helm-rendered objects, installed CRDs, stored CRD versions, and the external Argo workload graph were unavailable to this audit. Before selecting any target above `v1.34.2`, compare every live and desired object against each intervening section of the official [Kubernetes deprecated API migration guide](https://kubernetes.io/docs/reference/using-api/deprecation-guide/). Also inspect API-request metrics or audit logs for deprecated endpoints; static manifests alone cannot detect controllers or clients still calling removed APIs.

Admission remains an upgrade dependency. cert-manager and Longhorn install admission webhooks; any webhook whose service has no ready endpoint, whose certificate is invalid, or whose `admissionReviewVersions` is unsupported can reject or stall object creation during migration. The live `MutatingWebhookConfiguration` and `ValidatingWebhookConfiguration` objects, serving pods, endpoint slices, CA bundles, and failure policies must therefore pass preflight. Do not bypass admission merely to make the upgrade proceed.

## Zero-downtime constraints

Zero Application Workload downtime is credible only if all of these are demonstrated before draining the first old worker:

- the new pool has three Ready workers at the selected target version and matching supported OKE image, distributed across the intended availability domains;
- all required DaemonSets, especially Longhorn and NGINX Ingress, are ready on the new workers;
- every Longhorn volume is healthy and replicas have rebuilt onto safe nodes; capacity and node/disk scheduling permit three replicas;
- every application has enough replicas, readiness probes, topology distribution, and a PodDisruptionBudget that permits one-at-a-time voluntary disruption; single-replica or ReadWriteOnce workloads need an application-specific migration proof because eviction plus volume detach/attach commonly creates an availability gap;
- OKE load-balancer backends have converged to ready ingress pods before old ingress pods disappear;
- every Argo CD Application is `Healthy` and `Synced`, and application-specific functional checks pass.

Kubernetes documents that drain uses the eviction API and respects PodDisruptionBudgets, but PDBs only constrain voluntary disruptions; they do not create redundancy ([Safely drain a node](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/), [Pod disruption budgets](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)). Consequently, an un-evictable PDB blocks migration, while a permissive PDB on a single replica does not guarantee availability.

## Mandatory live preflight (currently unverified)

Treat each item below as a go/no-go gate:

- Record server version, OKE cluster lifecycle state, available upgrade versions, node-pool versions/images, worker conditions, allocatable headroom, quotas, subnet IP headroom, and load-balancer health. OCI requires upgrading the control plane before node pools and notes Kubernetes version-skew constraints in its [OKE cluster upgrade procedure](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengupgradingk8smasternode.htm).
- Inventory all API resources and objects without reading Secret payloads; scan live objects, rendered Helm releases, and the exact Argo Git revision for removed APIs and deprecated endpoint use.
- Verify all admission webhooks, CRDs, stored versions, conversion webhooks, APIService objects, CSI drivers, StorageClasses, PV/PVC attachment state, and Longhorn node/volume/replica health.
- Verify every Deployment, StatefulSet, DaemonSet, PodDisruptionBudget, probe, affinity/topology rule, and local-storage dependency. Dry-run the intended cordon/drain sequence and resolve any blocked eviction before the window.
- Verify Velero BackupStorageLocation availability, BackupRepository readiness, node-agent readiness, and a fresh completed backup with no warnings/errors; then complete the already-required representative stateful restore rehearsal and application validation.
- Snapshot the baseline: Argo `Healthy`/`Synced`, all workload readiness, ingress/TLS/DNS checks, storage health, and application functional checks. Use the same checks as migration acceptance criteria.

## Repository changes required before execution planning

- Replace the worker-image fallback with a precondition or failing lookup when no exact target-version OKE image exists.
- Pin and record the exact target version, exact worker image OCID/name, and exact Argo workload Git revision used by preflight.
- Decide and document the Longhorn node-drain policy and the workload-by-workload migration order.
- Add explicit commands and expected results for all live gates above, including the fresh backup and restore rehearsal.

Until those live checks pass, the correct readiness result is **blocked**, and the claimed zero-downtime outcome is unproven.
