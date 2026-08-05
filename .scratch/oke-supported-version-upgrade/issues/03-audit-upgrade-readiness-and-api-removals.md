# Audit live upgrade readiness and Kubernetes API removals

Type: research
Status: resolved
Blocked by: none

## Question

What current Live State, Terraform configuration, Argo-managed manifests, deprecated or removed Kubernetes APIs, admission or storage dependencies, backup health, and OCI prerequisites could block an upgrade beyond `v1.34.2` or invalidate the zero-Application-Workload-downtime requirement?

## Answer

The audit is recorded in [OKE upgrade readiness and API-removal audit](../../../docs/research/oke-upgrade-readiness-and-api-removals.md). Repository configuration exposes an unsafe worker-image fallback, external/unscanned Argo workload manifests, strict three-replica Longhorn scheduling constraints, and Velero file-system backups whose live health and restoreability cannot be inferred from configuration. Read-only live access was not approved, so API removals, admission health, workload disruption budgets, storage health, backup health, OCI capacity, and zero-downtime feasibility remain mandatory go/no-go gates rather than established facts.
