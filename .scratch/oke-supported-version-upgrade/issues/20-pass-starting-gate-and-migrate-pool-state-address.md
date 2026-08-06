# 20 — Pass the starting gate and migrate the pool state address

**What to build:** Establish the complete production baseline, record Approval Gate 1, and apply the exact validated full Infrastructure plan that preserves the existing `v1.34.2` worker pool, reconciles redundant controller-created security rules, and accepts only a semantically equivalent kubeconfig replacement.

**Blocked by:** 19 — Publish and validate the operator package; 35 — Prepare Gate 1 plan remediation; 36 — Disable OKE security-list management

**Status:** ready-for-human

- [ ] No command that mutates Infrastructure State or Live State runs until the human approves the exact starting evidence, the saved full plan's SHA-256, and the validator result.
- [ ] The baseline proves the cluster, existing workers, APIs/admission components, Shared Platform Services, Longhorn storage, Argo Applications, ingress, Application Workloads, backups, repositories, and Backup Storage Location satisfy Approval Gate 1.
- [ ] OCI still offers exact next hop `v1.35.2`, and current OKE skew rules permit the approved retained-worker sequence.
- [ ] Fresh backups for `staging`, `vaultwarden`, and `openvpn` are recorded as `Completed` with zero errors and warnings; restoreability is explicitly recorded as unproven.
- [ ] The Gate 1 validator proves that every worker-pool identity and configuration invariant is unchanged, the existing pool is preserved through the intended state-address move, and no pool is created, updated, replaced, or destroyed.
- [ ] After canonicalization, the only permitted semantic OCI security-list effects are removal of any still-present subset of the initially captured NGINX HTTP, HTTPS, and health-check port rules from each relevant list; no effective base rule is added, removed, broadened, narrowed, or changed.
- [ ] Kubeconfig replacement is accepted only when endpoint, certificate authority data, cluster OCID, region, authentication command and arguments, and output path are unchanged, the resulting mode is `0600`, and content differences are limited to internally consistent aliases.
- [ ] The approved full Infrastructure plan contains no resource action outside the state-address preservation, removal of any still-present subset of the six initially captured redundant rules, and semantically equivalent kubeconfig replacement.
- [ ] Terraform applies the exact saved plan artifact whose SHA-256, evidence, and validator result were approved; any regenerated plan requires fresh validation and approval.
- [ ] After the authorized apply, a second full plan reports no changes.
- [ ] Any unexpected drift or plan effect pauses the ticket without applying or using `terraform -target`.

## Comments

- 2026-08-05T20:46:46Z Gate 1 execution paused before approval or apply. No
  Infrastructure State or Live State mutation was run, and `terraform -target`
  was not used.
- Read-only evidence is stored under the private mode-`0700` directory
  `/private/tmp/oke-gate1.lYCcot`; its files and the untracked
  `gate1-worker.tfvars` overlay are mode `0600`. The overlay records the
  existing pool's observed name, exact `v1.34.2` version, size, and image so the
  refactored configuration can be planned without changing the old pool.
- The partial health snapshot passed for the API server, three Ready
  `v1.34.2` nodes, all Deployments and DaemonSets, non-completed pods, and all
  five Healthy/Synced Argo Applications at the audited revisions. All five
  Longhorn volumes were attached and healthy with three running `RW` replicas;
  all Longhorn nodes and disks were Ready and schedulable.
- OCI reported the cluster and three-node pool `ACTIVE` on `v1.34.2`, offered
  exact next hop `v1.35.2`, and listed `v1.36.1` regionally. Current OCI
  documentation permits the retained-worker sequence because Kubernetes 1.28+
  allows workers to lag the control plane by up to three minor versions.
- The latest scheduled `staging`, `vaultwarden`, and `openvpn` backups were
  created at `2026-08-05T00:00:12Z`, `Completed`, and reported zero errors and
  warnings. Their Kopia BackupRepositories were `Ready` and the Backup Storage
  Location was `Available`. No restore rehearsal occurred, so restoreability
  remains unproven.
- The required full Infrastructure plan was not approvable. It exited `1`,
  proposed replacement of `local_file.k8s_cluster_kube_config_file`, updates to
  both OCI security lists (`1 to add, 2 to change, 1 to destroy` overall), and
  failed the retained-pool image precondition because the existing `v1.34.2`
  image is no longer present in OCI's currently available worker image catalog.
  The failed plan transcript SHA-256 is
  `f5e627dcd4c8addb0b28d126cbe34ffcbda0c0c94d685ecba9ed6c7fb2b7dfa4`.
- Per the fail-closed rule, no Platform plan, approval, state-address apply, or
  follow-up plan was attempted. Gate 1 remains open pending human-reviewed
  remediation of the image-validation conflict and unrelated plan effects,
  followed by a complete fresh evidence snapshot and new full plans.
- 2026-08-06 remediation design approved. Ticket 35 prepares explicit Candidate
  and Retained Worker Pool validation, exclusive Terraform security-list
  ownership configuration, and the saved-plan validator without state or live
  mutation. Ticket 36 then disables OKE security-list management through an
  isolated approved Platform apply. Gate 1 will be retried only after both
  prerequisites resolve and all evidence and plans are freshly captured.
