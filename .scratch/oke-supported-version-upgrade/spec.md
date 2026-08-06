# Upgrade production OKE to Kubernetes v1.36.1

Status: ready-for-agent

## Problem Statement

The production OCI Kubernetes Engine cluster runs Kubernetes `v1.34.2`, while OCI now offers newer releases. The cluster cannot safely reach the frozen target `v1.36.1` through a single version change: OKE requires an intermediate control-plane hop, the current Terraform model couples control-plane and worker versions, worker image selection can silently fall back to an unrelated image, and the installed Shared Platform Services require carefully staged upgrades.

The cluster also runs singleton Application Workloads backed by Longhorn `ReadWriteOnce` volumes. Literal zero downtime is not achievable with the current workload design, and Velero restoreability is unproven because no restore rehearsal will be performed. The upgrade therefore needs a controlled blue/green worker migration, fresh backup evidence, explicit approval gates, and a retained old pool for worker-only rollback until Migration Acceptance.

The repository must first be made capable of expressing and operating this sequence safely. Repository preparation and production execution must remain separate: completing or approving repository changes does not authorize any OCI, Kubernetes, Infrastructure State, Platform State, or Argo CD mutation.

## Solution

Prepare the repository for a two-hop OKE upgrade whose target and compatibility decisions are frozen as of August 2026. Refactor Infrastructure configuration so the control-plane version is independent of a version-keyed collection of worker pools. Require an exact, explicitly approved OKE image for each worker generation and fail closed on absence or mismatch. Preserve the existing `v1.34.2` pool through a declarative Terraform state-address move and protect all worker pools from destruction throughout the upgrade and migration.

Classify each worker generation explicitly as a Candidate Worker Pool or Retained Worker Pool. Both dispositions fail closed on live image identity, Kubernetes version, and approved operating-system family; Candidate Worker Pools additionally require their pinned image to remain currently available for provisioning. Terraform exclusively owns OCI security lists, so the NGINX LoadBalancer disables OKE security-list management before Gate 1 reconciles the controller-created rules. Keep the generated kubeconfig Terraform-managed, but admit its replacement only when a machine-checkable semantic comparison proves that security-relevant content and file protections are unchanged.

Prepare the Shared Platform Services for serial, CRD-aware upgrades on Kubernetes `v1.34.2`: Longhorn first, then Velero, cert-manager, F5 NGINX Ingress Controller, and Argo CD. Preserve Terraform's ownership of Infrastructure, Shared Platform Services, the Bootstrap Seed, Repository Registration, and Explicit Secrets. Preserve Argo CD's ownership of Application Workloads and Application Namespaces.

Publish an operator-ready runbook and evidence template that separate repository preparation from live execution. The live runbook uses six evidence-bound approval gates and proceeds through platform upgrades, control-plane hops `v1.34.2 → v1.35.2 → v1.36.1`, creation of a three-node `v1.36.1` pool, serial worker migration, Migration Acceptance, and guarded old-pool retirement. Failed gates pause progression. The control plane is never downgraded; worker migration may roll back to the retained `v1.34.2` pool until that pool is deleted.

No live action is implied by this specification. Live execution begins only after a human explicitly authorizes the applicable action and its exact evidence or Terraform plan.

## User Stories

1. As the cluster operator, I want the target fixed at Kubernetes `v1.36.1`, so that the upgrade does not silently drift to a newly released patch.
2. As the cluster operator, I want the control plane to pass through `v1.35.2`, so that every OKE control-plane hop follows OCI's supported sequence.
3. As the cluster operator, I want OCI availability re-queried before each control-plane hop, so that stale research never authorizes an unavailable version.
4. As the cluster operator, I want OCI worker-skew support revalidated before the `v1.36.1` hop, so that retaining the `v1.34.2` rollback pool remains supported.
5. As the infrastructure maintainer, I want the control-plane version independent of worker-pool versions, so that control-plane upgrades do not implicitly replace or upgrade workers.
6. As the infrastructure maintainer, I want worker generations represented as a version-keyed collection, so that old and new pools can coexist in Terraform.
7. As the infrastructure maintainer, I want every worker generation to declare an exact image OCID, so that plans are reproducible.
8. As the infrastructure reviewer, I want worker image metadata validated against the requested Kubernetes version and OS family, so that a mismatched image fails closed.
9. As the infrastructure reviewer, I want the unsafe image fallback removed, so that Terraform never selects an arbitrary OKE image.
10. As the infrastructure maintainer, I want the existing pool moved declaratively to its version-keyed address, so that the refactor does not recreate production workers.
11. As the cluster operator, I want worker pools protected from destruction during upgrades and migration, so that the rollback pool cannot be removed accidentally.
12. As the cluster operator, I want a three-node paid `v1.36.1` pool created alongside the existing pool, so that worker migration can proceed blue/green.
13. As the platform maintainer, I want every Shared Platform Service upgraded to the frozen compatible release set before the control plane changes, so that Kubernetes `v1.36.1` does not outrun platform support.
14. As the platform maintainer, I want each service and minor-version hop applied separately, so that a failed rollout has a narrow diagnosis boundary.
15. As the platform maintainer, I want each release's required CRDs handled with its matching procedure, so that controllers and stored custom resources remain compatible.
16. As the storage operator, I want Longhorn upgraded first and validated after every hop, so that persistent storage is healthy before later platform changes.
17. As the backup operator, I want Velero, its AWS plugin, node agent, restore helper, and CRDs upgraded as matching sets, so that backup creation remains coherent.
18. As the certificate operator, I want cert-manager CRDs placed under the current Helm ownership mechanism, so that later chart upgrades manage CRDs consistently.
19. As the ingress operator, I want the F5 NGINX migration to preserve the existing Service identity and selectors, so that the OCI Load Balancer is not replaced.
20. As the Argo CD operator, I want the complete Argo CD release and CRD set upgraded through every required hop, so that the Bootstrap Seed and Application graph remain usable.
21. As the application owner, I want bounded maintenance interruptions explicitly accepted, so that the runbook reflects the singleton and `ReadWriteOnce` workload design honestly.
22. As the application owner, I want workloads moved and validated serially where practical, so that one failure does not intentionally interrupt every Application Workload.
23. As the storage operator, I want one old worker drained at a time, so that Longhorn can rebuild three healthy replicas before migration continues.
24. As the network operator, I want OpenVPN used in the canary migration, so that UDP connectivity and its persistent volume are proven early.
25. As the application owner, I want HTTP/TLS, OpenVPN, Vaultwarden, and Medusa checks repeated after affected migrations, so that readiness is established through user-visible behavior.
26. As the backup operator, I want fresh successful backups for every stateful Application Namespace before disruptive work, so that current backup creation and External Backup Store access are proven.
27. As the approver, I want backup names, timestamps, namespaces, repository state, and storage-location state recorded, so that approval refers to immutable evidence.
28. As the approver, I want six explicit go/no-go boundaries, so that irreversible and disruptive transitions cannot happen implicitly.
29. As the approver, I want every approval tied to the exact plan and health evidence reviewed, so that changed conditions invalidate stale approval.
30. As the Terraform reviewer, I want full plans rather than targeted plans, so that unrelated or destructive drift cannot be hidden.
31. As the Terraform reviewer, I want any change to Explicit Secret data, protected resources, or the ingress Load Balancer to stop the phase, so that upgrade work does not cross ownership or safety boundaries.
32. As the cluster operator, I want a failed gate to pause the runbook without an elapsed-time trigger, so that evidence rather than a clock determines progression.
33. As the cluster operator, I want the control plane left on its successfully upgraded version after a later failure, so that the runbook never attempts an unsupported downgrade.
34. As the cluster operator, I want failed worker migration to return workloads and Shared Platform Services to the retained old workers, so that worker recovery does not depend on control-plane rollback.
35. As the incident investigator, I want a failed new pool retained and cordoned after rollback, so that evidence is preserved for diagnosis.
36. As the cluster operator, I want Migration Acceptance to cover workloads, storage, ingress, Argo, functional checks, and post-migration backups, so that running pods alone cannot authorize cleanup.
37. As the cluster operator, I want old-pool deletion split into a no-change protection-removal review and a destruction-only review, so that cleanup is deliberate.
38. As the application owner, I want the old pool removed only after every Application Workload is live and synchronized on the new workers, so that rollback capacity is not retired prematurely.
39. As the operator receiving handoff, I want final versions, image OCIDs, plans, work requests, backup identifiers, approvals, and verification results recorded, so that the completed upgrade is auditable.
40. As the risk owner, I want unproven restoreability, singleton workloads, and loss of worker rollback after cleanup recorded explicitly, so that residual risk is not mistaken for resolved risk.
41. As the repository maintainer, I want repository preparation to stop before any live apply or state move, so that an implementation agent cannot accidentally operate production.
42. As the production owner, I want every live mutation to require explicit human authorization, so that an agent-ready repository ticket is never treated as execution permission.
43. As the infrastructure reviewer, I want Candidate Worker Pools distinguished from Retained Worker Pools, so that catalog retirement cannot block preservation of a correctly pinned running pool while creation still fails closed.
44. As the infrastructure reviewer, I want the refreshed identity and image metadata of every worker pool checked against its pinned declaration, so that retained status never bypasses mismatch detection.
45. As the network operator, I want Terraform to be the sole owner of OCI security lists, so that OKE and Terraform do not repeatedly undo each other's rule changes.
46. As the approver, I want Gate 1 evaluated by a machine-checkable saved-plan validator, so that only the explicitly approved reconciliation effects can pass.
47. As the cluster operator, I want a kubeconfig replacement accepted only when its endpoint, trust, cluster identity, authentication, region, path, and permissions remain equivalent, so that generated alias churn cannot hide a security-relevant change.

## Implementation Decisions

- The work has two authorization domains. Repository Preparation creates reviewable configuration, documentation, and operator artifacts only. Live Cluster Execution includes every Terraform apply, authoritative state-address move, Shared Platform Service rollout, CRD apply, control-plane update, worker-pool creation or deletion, Kubernetes cordon/drain, Longhorn scheduling change, and Argo CD mutation. Live Cluster Execution requires separate explicit authorization.
- The frozen Kubernetes target is `v1.36.1`. The control plane follows `v1.34.2 → v1.35.2 → v1.36.1`. OCI must offer the exact next version at execution time; no other patch may be substituted automatically.
- Infrastructure exposes `control_plane_kubernetes_version` independently from a `worker_pools` map implemented with `for_each`.
- Each worker-pool entry is keyed by immutable Kubernetes generation and declares a stable OCI name, Kubernetes version, size, exact image OCID, and explicit `candidate` or `retained` disposition. The model supports simultaneous `v1.34.2` and `v1.36.1` entries.
- Worker image selection is explicit and fail closed. Every pool's refreshed OCI pool identity, pinned image OCID, source type, source name, exact OKE Kubernetes version, and approved Oracle Linux family must match its declaration. A Candidate Worker Pool must additionally resolve uniquely in OCI's currently available worker-image catalog; a Retained Worker Pool remains valid when its matching pinned image has retired from that catalog. Dynamic newest-image selection and unrelated-image fallback are removed.
- A Candidate Worker Pool becomes a Retained Worker Pool only after it is `ACTIVE`, every intended worker is `Ready`, its image identity is verified, and its qualification gate passes. The disposition change must produce a reviewed plan with no Infrastructure change. The existing `v1.34.2` pool starts retained; the future `v1.36.1` pool starts candidate.
- The current pool is preserved with a declarative move from its count-addressed blue/green resource instance to the `v1.34.2` map entry. The first authorized state migration may also reconcile any still-present subset of the six initially captured redundant controller-created security-list rules and replace the generated kubeconfig, but only under the Gate 1 saved-plan allowlist; it must not mutate any OCI resource beyond those approved rule removals or change the worker pool.
- Worker-pool lifecycle uses create-before-destroy behavior and destruction protection throughout control-plane upgrades and worker migration. Destruction protection is removed only after Migration Acceptance and only while both pool entries remain configured.
- Shared Platform Services remain Terraform-Managed Resources in Platform State. The Bootstrap Seed, bootstrap Repository Registration, and Explicit Secrets remain Terraform-managed. Application Workloads and Application Namespaces remain Argo-managed. Generated Resources continue to follow their managed parents.
- Terraform exclusively owns OCI security lists and their complete rule sets. Before the Gate 1 Infrastructure plan is approved, a separately approved Platform plan sets the NGINX LoadBalancer's OKE security-list management mode to `None` without replacing the Helm release, Service, or OCI Load Balancer or changing its addresses or ports. If ingress or LoadBalancer health fails, restore the previous annotation behavior through Platform Terraform and leave Gate 1 paused. If the change succeeds but Gate 1 later pauses, leave management disabled and the verified post-change rules intact.
- The generated kubeconfig remains Terraform-managed as a Local Sensitive Artifact. Gate 1 may admit its replacement only when semantic comparison proves that the API endpoint, certificate authority data, cluster OCID, region, authentication command and arguments, and output path are unchanged, that the resulting mode is `0600`, and that content differences are limited to internally consistent cluster and context aliases.
- Longhorn upgrades serially through `1.7.2 → 1.8.2 → 1.9.2 → 1.10.2 → 1.11.3 → 1.12.0`. Each chart/application hop uses its matching CRD lifecycle and must return every node, disk, volume, engine, and replica to healthy state before continuing. The V2 engine and unrelated storage migration remain disabled.
- Velero upgrades through four matching sets: chart/app/AWS plugin `8.7.2/1.15.2/1.11.1`, `10.1.3/1.16.2/1.12.2`, `11.4.0/1.17.1/1.13.2`, and `12.1.0/1.18.1/1.14.2`. Each set also pins its matching node-agent, restore-helper, and server images. CRDs for the exact Velero minor are applied before its Helm hop because automatic CRD upgrades remain disabled.
- cert-manager upgrades one minor at a time through `v1.17.4`, `v1.18.6`, `v1.19.6`, `v1.20.3`, and `v1.21.1`. The legacy CRD setting is replaced with the current Helm-managed CRD setting before the first hop, and Helm ownership of installed CRDs is confirmed.
- F5 NGINX Ingress Controller follows chart/application hops `1.4.2/3.7.2`, `2.0.1/4.0.1`, and `2.6.4/5.5.4`. Matching F5 CRDs precede major-version hops. The 3.x-to-4.x migration preserves the existing Service name, controller name, selector labels, OCI Load Balancer identity, addresses, and backends.
- Argo CD follows chart/application hops `7.7.23/2.13.4`, `7.9.1/2.14.11`, `8.2.7/3.0.12`, `9.0.6/3.1.9`, `9.3.7/3.2.6`, `9.5.11/3.3.9`, `10.2.2/3.4.6`, `10.2.3/3.5.0`. Every hop upgrades the complete Helm release and matching CRDs while preserving the Bootstrap Seed and Repository Registration.
- Platform services upgrade in strict order on Kubernetes `v1.34.2`: Longhorn, Velero, cert-manager, F5 NGINX Ingress Controller, then Argo CD. All hops for one service finish before the next service begins. Multiple declared minor hops are never combined in a single apply.
- The operator artifacts include a durable runbook, a per-phase evidence template, approval records, expected Terraform plan shapes, live read-only checks, functional-check definitions, rollback instructions, and final handoff fields. Sensitive values and Local Sensitive Artifacts are never committed.
- The runbook uses six named approval gates: starting baseline; completion of all platform upgrades; the `v1.35.2` control-plane apply; the `v1.36.1` control-plane apply; first old-worker cordon; and Migration Acceptance before deletion protection is weakened.
- Every approval is bound to the exact saved plan artifact, its SHA-256, and the recorded evidence. Relevant drift, a failed check, configuration change, regenerated plan, OCI availability or skew change, or materially changed reconciled Application Workload revision invalidates approval. Terraform applies the exact approved saved plan; any regenerated plan requires validation and approval again.
- Full Terraform plans are mandatory for every phase. Targeted planning or application is prohibited. Plans containing effects outside the phase's explicit machine-checkable allowlist, protected-resource replacement, Explicit Secret data mutation, unapproved images, or ingress Load Balancer replacement fail closed.
- Gate 1 uses a repository validator over the saved full Infrastructure plan and fresh captured evidence. After canonicalizing provider representation, it permits only preservation through the worker-pool address move, removal of any still-present subset of the three captured NGINX NodePorts or health-check port rules from each of the two OCI security lists, and a semantically equivalent kubeconfig replacement. It verifies every retained-pool identity and configuration invariant, emits no sensitive content, and rejects every other action.
- The starting baseline requires an `ACTIVE` `v1.34.2` control plane, three `Ready` `v1.34.2` workers, supported skew, compatible observed APIs/admission components, healthy Shared Platform Services, five Longhorn volumes with three healthy replicas, Healthy/Synced Applications, functional ingress/application/VPN checks, fresh successful backups, healthy Kopia repositories, an available Backup Storage Location, and no Terraform effect outside the Gate 1 allowlist.
- No restore rehearsal is performed. Fresh backups for `staging`, `vaultwarden`, and `openvpn` must be `Completed` with zero errors and warnings, their Kopia BackupRepositories must be `Ready`, and the Backup Storage Location must be available. Evidence records immutable backup names, timestamps, and included namespaces. This proves backup creation, not restoreability.
- After platform completion, the control plane upgrades alone to `v1.35.2`. The old worker entry remains `v1.34.2`. The OCI work request must complete and the cluster must return to `ACTIVE` before complete health gates are rerun.
- The `v1.36.1` control-plane hop starts only after OCI is re-queried from the `v1.35.2` cluster and still supports the exact target plus temporary `v1.34.2` workers. Otherwise the healthy cluster remains at `v1.35.2` and target selection is reopened.
- The replacement worker pool is created directly at `v1.36.1`; no `v1.35.2` worker pool is created. It contains exactly three workers using the approved image and availability-domain placement. All required CNI, CSI, kube-proxy, Longhorn, ingress, and Velero DaemonSets must be ready on the new workers before migration approval.
- The `v1.36.1` entry remains a Candidate Worker Pool through creation and qualification. Only after the pool is active, all three workers and required DaemonSets are ready, the pinned image identity is verified, and the qualification checks pass may a separately reviewed no-Infrastructure-change plan mark it retained.
- Worker migration proceeds one old worker at a time after live identities are re-resolved. The recorded risk order is the current nodes at `10.0.4.31`, `10.0.5.209`, and `10.0.5.148`. A changed placement requires reassessment rather than blindly applying the stored addresses.
- Each worker migration disables Longhorn replica scheduling on only that old node, cordons it, drains through the eviction API without forced deletion, waits for affected workloads and platform replicas, restores every Longhorn volume to three healthy replicas with no pending operation, and reruns relevant Argo, endpoint, ingress, storage, OpenVPN, Vaultwarden, Echo, and Medusa checks.
- Bounded interruptions are accepted for singleton, `Recreate`, StatefulSet, and Longhorn `ReadWriteOnce` Application Workloads. High-availability redesign is not a prerequisite. An interruption never permits forced deletion or bypassing an exit gate.
- Failed gates pause progression without a time-based abort rule. The operator records evidence, preserves current state, performs supported forward repair, reruns the complete failed gate, and reacquires any invalidated approval. Shared Platform Services have no assumed generic downgrade path.
- The OKE control plane is never downgraded. A failed or indeterminate control-plane work request stops for OCI diagnosis and forward recovery.
- Worker-only rollback becomes available after migration begins and remains available until old-pool deletion. Storage degradation or fault, volume attachment/data failure, unstable new workers, or an Application Workload that cannot recover triggers rollback consideration. Affected workloads and Shared Platform Services return to uncordoned `v1.34.2` workers while the control plane stays on `v1.36.1`.
- Worker rollback retains both Terraform pool entries. Failed `v1.36.1` workers remain cordoned for diagnosis; repairing, replacing, or deleting that pool requires a later reviewed change and explicit authorization.
- Migration Acceptance requires every ordinary workload on the new pool, no Longhorn engine or replica on old workers, all three new workers and platform DaemonSets ready, all five volumes with three healthy new-pool replicas, all Applications Healthy/Synced, all controllers available, all endpoint and functional checks passing, and new successful post-migration backups with healthy repositories and storage location.
- Old-pool retirement is two reviewed changes. First, remove destruction protection while retaining both map entries and require a no-change plan. Second, remove only the `v1.34.2` entry and require a plan that destroys only that pool. Applying either change is Live Cluster Execution and requires explicit authorization.
- After old-pool deletion, repeat node, pod, DaemonSet, Longhorn, Argo, ingress, application, repository, and Backup Storage Location checks. Worker rollback is then unavailable; failures use forward repair and the accepted backup posture.
- Final handoff records the final Kubernetes and platform versions, image OCIDs, plans and applies, OCI work requests, node migration evidence, functional results, backup identifiers, approvals, post-removal verification, and residual risks.
- No bespoke maintenance duration, temporary-capacity cost ceiling, quota reservation, duration-based abort threshold, or calendar cleanup deadline is introduced. Successful provisioning is the capacity gate, and the old pool is removed immediately after Migration Acceptance and approval.

## Testing Decisions

- Do not add Terraform test files, mocked-provider tests, or a general unit or integration test suite solely for this upgrade. The Gate 1 saved-plan validator is an operator safety control and must have non-sensitive positive and negative fixtures proving that its allowlist accepts the approved plan shape and rejects changed pool identity, meaningful kubeconfig changes, security-rule changes outside the captured redundant ports, and unrelated resource actions.
- Repository Preparation still requires non-mutating quality checks: Terraform formatting and validation for both roots, syntax or rendering checks required by the selected chart/CRD mechanisms, documentation/link checks where already available, and inspection of the resulting configuration diff.
- Formatting and validation are not evidence that production behavior is safe. Live acceptance relies on reviewed full Terraform plans and the read-only OCI, Kubernetes, storage, backup, Argo, ingress, and functional evidence specified at each gate.
- A good plan review evaluates externally observable resource changes rather than Terraform expression structure. Each phase must show only its declared resource effects, and unexpected changes fail closed. Gate 1 security rules are compared canonically so provider normalization of an otherwise identical rule is not mistaken for a semantic effect.
- The state-address migration is accepted only when the validator proves that the authorized full plan preserves the existing pool, semantically removes at most the still-present subset of the six initially captured redundant controller-created security-list rules, changes only kubeconfig aliases, and contains no other effect. The following full plan must be empty.
- Platform hop acceptance is based on the matching CRD/Helm plan plus post-apply service health and user-visible behavior. Control-plane acceptance is based on the OCI work request, exact active version, and complete post-hop gates. Worker acceptance is based on node, DaemonSet, Longhorn, Argo, endpoint, and functional evidence.
- No validation command may perform `terraform apply`, `terraform import`, a Terraform state mutation, an Argo sync, a Kubernetes mutation, an OCI mutation, or a production workload restart without explicit authorization.

## Out of Scope

- Performing any live OCI, Kubernetes, Infrastructure State, Platform State, or Argo CD mutation as part of Repository Preparation.
- Automatically executing the production upgrade after repository artifacts are merged.
- Downgrading or rolling back an upgraded OKE control plane.
- Performing a Velero or Kopia restore rehearsal.
- Claiming that backups are restorable without a successful restore exercise.
- Redesigning Application Workloads for high availability, adding failover architectures, or changing replica/PDB/topology strategies solely to remove maintenance interruptions.
- Creating an intermediate `v1.35.2` worker pool.
- Enabling Longhorn's V2 engine or performing unrelated storage migration.
- Replacing the ingress OCI Load Balancer or changing the ownership boundary between Terraform and Argo CD.
- Rotating Explicit Secrets or changing their values as part of platform upgrades.
- Moving or managing the External Backup Store through Terraform.
- Automatically adopting newer Kubernetes patches, platform releases, plugins, CRDs, or worker images after the August 2026 freeze.
- Adding an automated test suite for this upgrade.
- Unrelated modernization, codebase refactoring, cost optimization, or disaster-recovery redesign.

## Further Notes

- The authoritative decision history is the completed [OKE supported-version upgrade Wayfinder map](map.md) and its resolved child tickets. This specification consolidates those decisions for implementation; the child tickets retain the detailed research evidence and reasoning.
- OCI availability, OKE worker-skew support, exact image availability, and Live State health remain execution-time facts. Repository configuration must not turn the August research snapshot into unconditional authorization.
- The exact Application Workload revisions audited during planning were `k8s-charts@eec87a3274e2b753e66939d6b2786fb728d8fb05` and `my-medusa-store@06a825efd520771cd2c04500c10f0eb6b371aeaf`. Materially different reconciled revisions invalidate workload-related approval evidence.
- Restoreability remains deliberately unproven. The retained `v1.34.2` pool is the primary worker-migration recovery mechanism until Migration Acceptance and deletion.
- All real variable files, Terraform states, state backups, saved plans, generated kubeconfigs, credentials, and evidence containing sensitive data are Local Sensitive Artifacts and must remain untracked with restrictive permissions.
- The next flow is to split this specification into dependency-ordered implementation tickets. Repository Preparation tickets should be agent-ready; any ticket that performs Live Cluster Execution must be clearly marked for explicit human authorization and must not inherit permission from this spec.
