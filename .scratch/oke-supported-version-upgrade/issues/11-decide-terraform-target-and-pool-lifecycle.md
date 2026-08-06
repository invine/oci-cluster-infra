# Decide Terraform target and worker-pool lifecycle representation

Type: grilling
Status: resolved
Blocked by: 01, 04

## Question

How should Terraform represent the `v1.35.2` and `v1.36.1` control-plane hops, exact matching OKE worker images, temporary paid blue/green pool, worker-only rollback, and old-pool removal while replacing the current unsafe image fallback with a fail-closed design?

## Answer

Separate the control-plane target from worker-pool generations. Terraform must expose one independently changeable `control_plane_kubernetes_version` and a version-keyed `worker_pools` map implemented with `for_each`. Do not encode the upgrade as a single shared Kubernetes version, an `upgrade_phase` switch, or additional duplicated legacy/new pool resources.

Each `worker_pools` entry must declare at least its stable OCI name, Kubernetes version, size and exact OKE worker image OCID. The map key is the immutable Kubernetes generation, including `"v1.34.2"` and `"v1.36.1"` for this upgrade. Both entries may coexist, making paid blue/green capacity and worker-only rollback explicit in Terraform configuration.

### Fail-closed worker images

Require an explicitly pinned image OCID for every pool generation. Terraform must look up and validate that image before creating or updating a pool, including confirming that its OKE image metadata/name exactly matches the entry's Kubernetes version and approved operating-system family. A missing image, unreadable image, version mismatch, or OS mismatch must fail planning or an apply precondition.

Delete the current fallback that selects the first available OKE image when no exact version match exists. Do not dynamically select the newest matching image during an upgrade apply; discovering and approving a replacement image OCID is a separate configuration change.

### Existing-pool state migration

The existing OCI pool is version-named but is currently count-addressed in Terraform state as `oci_containerengine_node_pool.oke-node-pool-bluegreen[0]`. Preserve it by declaring a Terraform `moved` block to the new address `oci_containerengine_node_pool.worker_pool["v1.34.2"]`.

Apply this representation refactor before any Kubernetes upgrade. Its full baseline plan must show the state-address move and no OCI pool destruction, replacement, or other infrastructure mutation. Any proposed replacement of the existing pool stops the upgrade. Prefer this declarative move over a manual `terraform state mv` so the migration is reviewable and reproducible.

### Control-plane and pool phases

Use full Terraform plans and applies for every phase; do not use `terraform -target`:

1. Refactor the existing pool into the version-keyed map and prove a no-replacement baseline plan.
2. Set only `control_plane_kubernetes_version` to `v1.35.2` and apply. Keep the sole worker entry fixed at `v1.34.2`.
3. After the required OCI re-query and hop gates pass, set only the control-plane version to `v1.36.1` and apply. Keep the old worker entry fixed at `v1.34.2`.
4. Add the `v1.36.1` worker entry with its approved exact image OCID and create the three-node replacement pool. Retain the complete `v1.34.2` entry and pool.
5. Perform the separately defined worker migration and Migration Acceptance Gate.
6. Retire the `v1.34.2` entry only through the guarded cleanup sequence below.

Every full plan must contain only changes expected for its phase. The control plane is never rolled back by this plan.

### Destruction and rollback behavior

Set `prevent_destroy = true` on the version-keyed worker-pool resource throughout the control-plane upgrade and worker migration. This deliberately makes removal of either map entry fail closed.

If worker migration fails, keep both pool entries in Terraform, leave the control plane on `v1.36.1`, migrate workloads and Shared Platform Services back to the retained `v1.34.2` pool, and cordon the failed `v1.36.1` pool for diagnosis. Do not destroy it as part of the immediate rollback. Its later repair, replacement, or removal requires a separate reviewed Terraform change.

After the Migration Acceptance Gate confirms that all Application Workloads and Shared Platform Services are live and synchronized on `v1.36.1`, retire the old pool through two reviewed changes:

1. Remove `prevent_destroy` while retaining both map entries. The full plan must show no infrastructure changes.
2. Remove only the `v1.34.2` entry. The full plan must show destruction of only the old pool; any additional change stops cleanup.

Apply the second change immediately after its plan is approved. Re-run the post-removal verification defined by the migration-gates ticket. Once the old pool is deleted, worker rollback is no longer available and subsequent failures use forward repair and the accepted backup posture.

## Comments

- 2026-08-06 Gate 1 execution refined the fail-closed image decision after OCI
  retired the correctly pinned image used by the running `v1.34.2` pool from
  its currently available worker-image catalog. Each entry now has an explicit
  Candidate or Retained Worker Pool disposition. Both validate refreshed pool
  identity and image metadata; only candidates additionally require current
  catalog availability. A candidate becomes retained only after qualification.
  This preserves creation safety without making catalog retirement invalidate
  an unchanged running pool. Ticket 35 implements the refinement.
