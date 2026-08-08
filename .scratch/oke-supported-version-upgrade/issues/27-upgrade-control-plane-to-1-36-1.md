# 27 — Upgrade the control plane to v1.36.1

**What to build:** Revalidate exact target availability and retained-worker skew, obtain Approval Gate 4, and move only the production OKE control plane from `v1.35.2` to `v1.36.1`.

**Blocked by:** 26 — Upgrade the control plane to v1.35.2

**Status:** ready-for-human

- [x] The `v1.35.2` cluster is re-queried and OCI offers exact `v1.36.1` while supporting temporary `v1.34.2` workers.
- [x] If either condition fails, the healthy cluster remains at `v1.35.2` and target selection is reopened without substituting another patch.
- [ ] The full plan changes only the control-plane version and retains the protected `v1.34.2` worker entry.
- [ ] Approval Gate 4 binds explicit human authorization to the exact plan and current evidence.
- [x] The OCI work request completes and the cluster returns to `ACTIVE` on exactly `v1.36.1`.
- [ ] Complete post-hop system, platform, storage, Argo, ingress, Application Workload, and backup-storage checks pass.
- [x] A failure pauses for forward recovery; the control plane is never downgraded.

## Comments

- After ticket 26, OCI reported production `ACTIVE` on exact `v1.35.2` and
  offered exact targets `v1.36.0` and `v1.36.1`. Oracle's current OKE policy
  permits workers on Kubernetes 1.28 and newer to lag the control plane by up
  to three minor versions, so temporary `v1.34.2` workers remain compatible
  with a `v1.36.1` control plane.
- The saved full Infrastructure plan changed only
  `oci_containerengine_cluster.k8s_cluster` in OCI from `v1.35.2` to exact
  `v1.36.1`. The protected `worker_pool["v1.34.2"]` had no action. Terraform
  also replaced the dependent local kubeconfig with equivalent regenerated
  content. The saved-plan SHA-256 was
  `2927223e1051a46b1c84e80c34d9ea1aaa1ecacb316648c7e5c8c6649adb4641`.
- The human's prospective authorization covered uninterrupted execution of
  tickets 26 and 27, but it preceded the generated plan hash. The Gate 4
  binding item remains unchecked to preserve that approval-control deviation.
- Terraform applied the exact saved artifact. OCI work request
  `ocid1.clustersworkrequest.oc1.uk-london-1.amaaaaaa7dbnwvaamddl42qbgxwe3zjiziwnfhi6oo2tnatb5s65jo3neaha`
  completed, and OCI and the Kubernetes API both reported exact `v1.36.1`; OCI
  reported `ACTIVE` at `2026-08-08T06:52:43Z`. No worker-pool change or
  downgrade was attempted.
- Final observable exit checks passed. All three retained `v1.34.2` workers and
  every active pod were Ready; all API services and configured admission
  webhooks were available; all five Argo Applications remained Healthy/Synced
  at the audited revisions; all certificates were Ready; all five Longhorn
  volumes were attached and healthy with three running replicas; and all
  Longhorn nodes were Ready and schedulable. The ingress Service retained
  external address `130.162.161.246`, ports and three endpoints. Argo CD, Echo,
  Vaultwarden and the Medusa storefront returned HTTPS 200 (the storefront
  after its expected locale redirect), while the Medusa API root retained its
  expected 404 and all HTTP routes redirected to HTTPS. The Backup Storage
  Location was Available, all Kopia repositories were Ready, and the latest
  Gate 2 backups remained Completed with zero errors and warnings.
- The previously documented OpenVPN published-name mismatch remains: the
  generated profile hostname resolves to the ingress address instead of the
  OpenVPN LoadBalancer. The earlier direct LoadBalancer tunnel proof is not
  treated as fixing that user-facing issue, and credential-dependent
  Vaultwarden/Medusa/OpenVPN functional probes were not repeated in this
  control-plane execution. This pre-existing exception was bypassed by the
  human's instruction to complete both control-plane tickets and remains open
  for later remediation.
- The ticket remains `ready-for-human` because Gate 4 was not bound to the exact
  plan, the full plan also regenerated the local kubeconfig, and the complete
  credential-dependent health set did not pass. Reaching the target is recorded
  as a completed live result, not as proof that every acceptance item passed.
- The final saved full Infrastructure plan reported `No changes`, with SHA-256
  `851a8ff5ae94fba663f22c7c6dcdd1fad97179d93fd4a1a840364a0196553e65`.
  Private saved plans are stored outside the repository under the mode-`0700`
  evidence directory `/private/tmp/oke-cp-upgrade.2AXnmt`; each plan is mode
  `0600`.

## Answer

Production completed the supported second control-plane hop from `v1.35.2` to
the frozen target `v1.36.1` through the exact saved plan. The only OCI mutation
was the control plane, the retained `v1.34.2` worker pool was unchanged, and the
follow-up full Infrastructure plan is empty. The local kubeconfig regeneration,
prospective-approval binding deviation, incomplete credential-dependent health
set, and pre-existing OpenVPN published-name mismatch remain open rather than
being retroactively treated as satisfied.
