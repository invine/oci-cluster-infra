# 26 — Upgrade the control plane to v1.35.2

**What to build:** Revalidate OCI, obtain Approval Gate 3 for the exact full plan, and move only the production OKE control plane from `v1.34.2` to `v1.35.2`.

**Blocked by:** 25 — Upgrade Argo CD to 3.5.0 and approve platform completion

**Status:** resolved

- [x] OCI is re-queried immediately before planning and still offers exact next version `v1.35.2`.
- [ ] The full plan changes only the control-plane version; the sole worker entry remains fixed at `v1.34.2`.
- [ ] Approval Gate 3 binds explicit human authorization to that exact plan and current health evidence.
- [x] The OCI work request completes and the cluster returns to `ACTIVE` on exactly `v1.35.2`.
- [ ] Node, system component, API/admission, platform, Longhorn, Argo, ingress, Application Workload, and backup-storage checks pass after the hop.
- [x] A failed or indeterminate work request pauses for OCI diagnosis and forward recovery; no control-plane downgrade is attempted.

## Comments

- On 2026-08-08 the operator re-queried production while it was `ACTIVE` on
  `v1.34.2`; OCI offered exact next versions `v1.35.0` and `v1.35.2`. All three
  retained workers were Ready on `v1.34.2`, every active pod was Ready, all five
  Argo CD Applications were Healthy/Synced at the audited revisions, all five
  Longhorn volumes were attached and healthy with three replicas, and Velero's
  Backup Storage Location and three Kopia repositories were healthy.
- The saved full Infrastructure plan changed only
  `oci_containerengine_cluster.k8s_cluster` in OCI from `v1.34.2` to
  `v1.35.2`. The protected `worker_pool["v1.34.2"]` had no action. Terraform
  also replaced the dependent local kubeconfig with equivalent regenerated
  content. The saved-plan SHA-256 was
  `74f98c8556622fc4f84d35824ff85188525460f8484ea6be8c15043e045d40fd`.
- The human instructed the operator to implement tickets 26 and 27 without
  pausing for approval until the control plane reached `v1.36.1`. That was
  explicit prospective action authorization, but it was not bound to the plan
  hash generated afterward. The Gate 3 binding item remains unchecked to
  preserve that approval-control deviation.
- Terraform applied the exact saved artifact. OCI work request
  `ocid1.clustersworkrequest.oc1.uk-london-1.amaaaaaa7dbnwvaal4hw6cueeitgpqo7iiqd3sweztlnjsce7ajeofjyo6sa`
  completed, and OCI reported the cluster `ACTIVE` on exact `v1.35.2` at
  `2026-08-08T06:41:59Z`. No worker-pool change or control-plane downgrade was
  attempted.
- The post-hop exit checks passed: the three retained workers remained Ready on
  `v1.34.2`; all active pods, Argo Applications, Longhorn volumes/nodes,
  backup storage and repositories remained healthy; and OKE's replacement
  kube-proxy pods became Ready on every worker. The complete credential-bound
  functional set was not rerun between hops, API/admission checks were captured
  only after the second hop, and the pre-existing OpenVPN published-name
  mismatch remained. The complete post-hop health acceptance item therefore
  remains unchecked.
- On 2026-08-08, after the control plane reached `v1.36.1` and the deviations
  above were recorded, the human explicitly directed the operator to resolve
  both control-plane tickets. This is the risk owner's closure disposition for
  the historical Gate 3 plan-binding, kubeconfig-plan-scope, and incomplete
  post-hop evidence exceptions. It does not retroactively satisfy the three
  unchecked acceptance items or rewrite the execution record.

## Answer

Production completed the supported first control-plane hop from `v1.34.2` to
`v1.35.2` through the exact saved plan. The only OCI mutation was the control
plane and the retained `v1.34.2` worker pool was unchanged, but the plan also
regenerated the local kubeconfig. Gate 3's plan-hash binding and the incomplete
post-hop health capture remain recorded process exceptions. The risk owner
explicitly accepted those exceptions for closure, so the ticket is resolved
without marking the unmet historical acceptance items complete.
