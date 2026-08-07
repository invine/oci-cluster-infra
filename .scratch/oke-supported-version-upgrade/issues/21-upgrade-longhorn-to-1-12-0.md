# 21 — Upgrade Longhorn to 1.12.0

**What to build:** Move the production Longhorn Shared Platform Service through every approved hop to `1.12.0`, validating storage fully after each isolated change.

**Blocked by:** 20 — Pass the starting gate and migrate the pool state address

**Status:** resolved

- [x] Each hop uses a separately reviewed full Terraform plan and receives explicit human authorization before apply.
- [x] The exact sequence `1.7.2 → 1.8.2 → 1.9.2 → 1.10.2 → 1.11.3 → 1.12.0` is followed without combining or substituting releases.
- [ ] Matching official pre-upgrade and CRD procedures complete for every hop. The risk owner explicitly waived the mandatory system and per-volume backup gates; the retained execution record also lacks the required per-volume audit timestamps and explicit data-path read/write results.
- [x] After each hop, managers, CSI components, supporting workloads, nodes, disks, volumes, engines, and replicas are healthy.
- [x] Every volume returns to three healthy replicas with no rebuild or storage operation pending before the next hop.
- [x] No V2-engine enablement, unrelated storage migration, Explicit Secret mutation, or other plan change occurs.
- [x] A failed check pauses progression for supported forward repair; no generic downgrade is assumed.

## Comments

- 2026-08-07 production execution followed the exact six-version sequence. Each
  destination used a separately saved full Platform plan whose only action was
  an in-place update of `helm_release.longhorn` (`0 to add, 1 to change,
  0 to destroy`). The plans were individually presented and explicitly
  authorized before apply. Their SHA-256 values were:
  - `1.8.2`: `2b604c618c9e64ca1b17deaeefd5a936d837e3a8afc7a416f0841dc96e358314`
  - `1.9.2`: `7be1c1feb3287202b9d3bc00376acbb0adb8eea9463e84525c847d44a91e8d18`
  - `1.10.2`: `6e46ef6cce23627c183e11ebca4f641a4dc5d910e0d7de7868a19afdda19f323`
  - `1.11.3`: `098bc26488988bb4fdab5860e4ef9a92fea8e1976db05ce9aef79a255c03b8ec`
  - `1.12.0`: `b43665e8459e13de8c495479999ed8aadde80645bca6a2587c06fb36db95beca`
- Official destination-specific requirements were checked before their hops.
  The `1.10.2` release used the required
  `backing-image-manager:v1.10.2-hotfix-1`; the cluster's Kubernetes `v1.34.2`
  satisfied the `1.11.3` CSI provisioner requirement; and the `1.12.0`
  preconditions confirmed only V1 data-engine volumes, V2 disabled, no Backing
  Images, no faulted volumes, and a supported Kubernetes version. Helm's
  pre-upgrade checker and chart-managed CRD upgrade path completed at every
  applicable hop.
- The risk owner explicitly directed execution without a new Longhorn backup
  because no Longhorn backup target is configured. This is an accepted
  deviation from the runbook's mandatory system-backup and per-volume-backup
  gates, not merely a recommendation; no Longhorn backup was created and this
  ticket does not claim restoreability.
- After every chart hop, all Longhorn managers, CSI components, supporting
  workloads, nodes, and disks converged healthy. The five engines were upgraded
  serially. Their five consuming workloads were then scaled down and back up one
  at a time to detach and reattach volumes. Every volume returned attached and
  healthy with exactly three running replicas before the next hop.
- The risk owner explicitly approved removal of unused images. After each hop,
  zero-reference EngineImages and superseded node images were removed only
  after verifying no live container references. One cleanup attempt was paused
  when terminating old pods still appeared in a snapshot; cleanup resumed only
  after those references reached zero. No downgrade was attempted.
- The execution used repository revision `456ace3`; Codex operated the upgrade
  and the human risk owner in this task approved each presented plan and live
  mutation. The saved plan artifacts and command transcripts were held only in
  private temporary/task context. The durable record retains the plan hashes,
  ordered version boundaries, aggregate engine/replica health, workload-to-
  volume identities, final placement, and the 2026-08-07 execution date. It
  does not retain exact per-volume start/end timestamps, interruption duration,
  or a row-by-row old/new-engine ledger. Those engine transitions can be
  inferred from the exact ordered hops but are not a substitute for the
  runbook-required audit fields.
- No explicit read/write result for each upgraded volume or representative
  bound-PVC exercise was captured. Serial detach/reattach, workload readiness,
  storage-object health, Argo health, and final public HTTP probes passed, but
  those checks do not prove the runbook's data-path test. This is a second
  evidence gap and the matching-procedures acceptance item remains unchecked.
- Final state is Helm chart/application `1.12.0`. All five V1 volumes are
  attached and healthy on the `1.12.0` engine, all fifteen replicas are
  running with one replica per node, the sole EngineImage is deployed with
  reference count 25, all three Longhorn nodes and disks are Ready and
  schedulable, and no non-completed pod is unhealthy. All five Argo
  Applications are Healthy and Synced.
- Final public probes for Echo, Medusa API, Medusa Storefront, Vaultwarden, and
  Argo CD returned HTTP `200` with successful TLS verification. The final full
  Platform plan exited `0` with `No changes`, proving that Live State matches
  the configured `1.12.0` destination.
- `terraform fmt -check -recursive`, `git diff --check`,
  `terraform -chdir=infra validate`, and `terraform -chdir=platform validate`
  passed. Provider-backed validation was run outside the filesystem sandbox
  after sandboxed provider startup was denied.
- The required two-axis review initially found the missing Wayfinder map pointer
  and overclaimed runbook compliance. After adding the pointer and explicitly
  preserving the backup, audit, and data-path deviations, Standards and Spec
  re-reviews reported no remaining findings.

## Answer

Longhorn is upgraded in production from `1.7.2` through every approved hop to
`1.12.0`. Storage, cluster workloads, Argo Applications, and public endpoints
are healthy, and the final full Terraform plan is empty. The accepted residual
risk includes the explicitly waived mandatory Longhorn backup gates: no
Longhorn backup target exists and restoreability was not established by this
ticket. The retained evidence also lacks exact per-volume audit timestamps and
explicit data-path read/write results, so the matching-procedures acceptance
item is intentionally left open rather than retroactively claiming compliance.
