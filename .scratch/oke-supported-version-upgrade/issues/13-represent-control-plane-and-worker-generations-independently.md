# 13 — Represent control-plane and worker generations independently

**What to build:** Refactor Infrastructure configuration so the OKE control plane and version-keyed worker generations can change independently, exact worker images fail closed, and the current `v1.34.2` pool can be preserved during an authorized state migration.

**Blocked by:** None — can start immediately

**Status:** resolved

- [x] The control-plane Kubernetes version has an input independent from all worker-pool versions.
- [x] Worker pools are represented with `for_each` over a version-keyed map containing stable OCI name, Kubernetes version, size, and exact image OCID.
- [x] Image validation rejects a missing or unreadable image and any OKE version or approved Oracle Linux family mismatch.
- [x] Dynamic newest-image selection and the unrelated-image fallback are removed.
- [x] The existing count-addressed pool has a declarative move to the `v1.34.2` map entry.
- [x] Worker pools use create-before-destroy behavior and destruction protection.
- [x] Tracked example inputs describe the current single-pool state without containing a real OCID or sensitive value.
- [x] Terraform formatting and non-mutating validation pass; no plan, apply, import, state command, or live API mutation is performed.

## Comments

- 2026-08-05 implementation completed in commits `3f67d0b` (`refactor: separate OKE worker generations`) and `4a08adf` (`refactor: clarify worker image validation`).
- Introduced independent `control_plane_kubernetes_version` and version-keyed `worker_pools` inputs. Each worker generation declares its stable OCI name, exact Kubernetes version, size, and pinned image OCID.
- Worker image validation now queries OCI's supported node-pool image catalog and requires exactly one source matching the pinned OCID, `IMAGE` source type, approved Oracle Linux 8 name prefix, and exact OKE Kubernetes version marker. The previous dynamic newest-image selection and unrelated-image fallback were removed.
- Added the declarative move from `oci_containerengine_node_pool.oke-node-pool-bluegreen[0]` to `oci_containerengine_node_pool.worker_pool["v1.34.2"]`, with `create_before_destroy` and `prevent_destroy` enabled.
- `terraform fmt -check -recursive`, `terraform -chdir=infra validate`, `terraform -chdir=platform validate`, and `git diff --check` passed. The required two-axis review reported zero Standards findings and zero Spec findings.
- No Terraform plan, apply, import, state command, or live OCI, Kubernetes, Platform State, Infrastructure State, or Argo CD mutation was performed.
- 2026-08-06 Gate 1 showed that catalog availability was too strong for the
  already-running pool: its exact pinned image and metadata still matched Live
  State after OCI stopped advertising the image for new provisioning. Ticket
  35 preserves this ticket's fail-closed identity checks while distinguishing
  Candidate Worker Pools, which require current catalog availability, from
  Retained Worker Pools, which do not.
