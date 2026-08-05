# Audit Argo workload disruption readiness

Type: research
Status: resolved
Blocked by: 03

## Question

At the exact Git revision reconciled by the live Argo CD graph, do any Application Workload manifests, rendered resources, replica counts, PodDisruptionBudgets, probes, topology constraints, persistent-volume modes, or Kubernetes APIs prevent migration to Kubernetes `v1.36.1` with zero Application Workload downtime?

## Answer

The exact live desired state was pinned and rendered: `k8s-charts@eec87a3274e2b753e66939d6b2786fb728d8fb05` for the bootstrap, Echo, OpenVPN, and Vaultwarden; `my-medusa-store@06a825efd520771cd2c04500c10f0eb6b371aeaf` for Medusa. All live Applications were `Synced` and `Healthy` when observed.

The literal zero-Application-Workload-downtime gate fails on static evidence. Every workload is a singleton; OpenVPN, Vaultwarden, and the Medusa backend use `Recreate`; PostgreSQL and Redis are single-replica StatefulSets; no PDB exists; Echo/OpenVPN/Vaultwarden and the Medusa worker lack readiness probes; and five Longhorn PVCs are `ReadWriteOnce`. There are no node-placement constraints blocking the new pool and no deprecated built-in Kubernetes API was found, although extension-API compatibility and live deprecated requests remain platform/runtime checks. The plan must either add real redundancy/failover and disruption controls or explicitly accept bounded interruption. A canary drain and live Longhorn detach/reattach proof remain mandatory. See [Argo workload disruption readiness for Kubernetes 1.36.1](../../../docs/research/argo-workload-disruption-readiness-2026-08-04.md).
