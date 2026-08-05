# Reconcile zero downtime with singleton Application Workloads

Type: grilling
Status: resolved
Blocked by: 09

## Question

Should the upgrade plan preserve literal zero Application Workload downtime by first adding real redundancy, failover, probes, rolling strategies, PodDisruptionBudgets, and placement controls—including an HA design for PostgreSQL, Redis, and other `ReadWriteOnce` state—or explicitly approve bounded maintenance interruptions for the current singleton and `Recreate` workloads?

## Answer

Explicitly accept planned, bounded Application Workload interruptions during the worker migration. Literal zero downtime is no longer an acceptance requirement for this upgrade.

The implementation plan must:

- perform disruptive moves only inside the declared maintenance window;
- migrate and validate workloads serially where practical rather than intentionally taking every Application Workload down together;
- expect interruption while singleton, `Recreate`, StatefulSet, and Longhorn `ReadWriteOnce` workloads terminate, detach, reattach, and become ready on the replacement pool;
- require each affected Application Workload to return to `Healthy` and `Synced` and pass its readiness, functional, ingress or OpenVPN, and storage checks before advancing;
- treat any interruption exceeding the time or abort threshold selected by [Set temporary capacity and maintenance guardrails](07-set-capacity-and-maintenance-guardrails.md) as a failed migration; and
- retain the old worker pool until the full Migration Acceptance Gate passes, so failed worker migration can return workloads to that pool without downgrading the control plane.

Do not add high availability, failover architectures, extra replicas, PodDisruptionBudgets, topology rules, or rolling-strategy redesign solely to eliminate upgrade downtime. Compatibility or correctness fixes independently required for Kubernetes `v1.36.1`, reliable health checks, backup/restore, or safe migration remain in scope.
