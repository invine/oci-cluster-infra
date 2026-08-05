# OKE v1.36.1 upgrade evidence template

Copy this template into a private, untracked evidence directory before Live
Cluster Execution. Do **not** complete it in the repository. Use process umask
`077`, directory mode `0700`, and file mode `0600`. Do not paste credentials,
secret values, real tfvars, state, kubeconfigs, saved-plan contents, or sensitive
raw output here; reference their protected local locations and checksums.

Controlling runbook: [`oke-v1.36.1-upgrade.md`](oke-v1.36.1-upgrade.md)

## Execution identity

| Field | Value |
| --- | --- |
| Change/incident reference | `<reference>` |
| Evidence directory | `<private untracked path>` |
| Evidence owner | `<name>` |
| Operator | `<name>` |
| Risk owner | `<name>` |
| Receiving owner | `<name>` |
| Cluster name / redacted OCID reference | `<value>` |
| OCI region/profile | `<value>` |
| Start UTC | `<timestamp>` |
| Infrastructure Git revision | `<sha>` |
| Reconciled k8s-charts revision | `<sha>` |
| Reconciled Medusa revision | `<sha>` |
| Audited k8s-charts baseline | `eec87a3274e2b753e66939d6b2786fb728d8fb05` |
| Audited Medusa baseline | `06a825efd520771cd2c04500c10f0eb6b371aeaf` |
| Material difference from audited workload behavior | `<none or STOP for new readiness review>` |
| Provider lock-file checksum(s) | `<sha256>` |
| Private-artifact permissions verified | `<yes/no, timestamp, operator>` |
| Repository `git status --short` checked | `<result, timestamp>` |

## Accepted posture

- [ ] The operator and risk owner acknowledge that repository readiness does not
  authorize Live Cluster Execution.
- [ ] Every live mutation will receive action-specific human authorization.
- [ ] Bounded interruptions are accepted for singleton, `Recreate`, StatefulSet,
  and Longhorn `ReadWriteOnce` Application Workloads.
- [ ] No forced pod deletion is authorized.
- [ ] No restore rehearsal will be performed; successful backups do not prove
  restoreability.
- [ ] The OKE control plane will never be downgraded.
- [ ] Worker-only rollback ends permanently when the old pool is deleted.

Acknowledged by / UTC: `<names and timestamp>`

## Reusable Terraform plan record

Create one copy for every plan. A regenerated plan receives a new record and
invalidates approval for the former plan.

| Field | Value |
| --- | --- |
| Phase / action | `<value>` |
| Terraform root | `<Infrastructure or Platform>` |
| Exact full-plan command | `<command; no -target>` |
| Configuration revision | `<sha>` |
| Variable-set reference, no values | `<protected reference>` |
| Saved-plan private path | `<protected reference>` |
| Saved-plan SHA-256 | `<sha256>` |
| Plan creation UTC | `<timestamp>` |
| Effect summary by resource | `<create/update/destroy/replacement>` |
| Expected phase shape matched | `<yes/no + rationale>` |
| Unrelated drift | `<none or STOP>` |
| Explicit Secret data change | `<none or STOP>` |
| Protected replacement/destruction | `<none or exact authorized old pool>` |
| Ingress Service/LB identity change | `<none or STOP>` |
| Exact versions/images/placement | `<values>` |
| Reviewer / UTC | `<name, timestamp>` |
| Review decision | `<go/no-go>` |
| Explicit action approver / UTC | `<name, timestamp>` |

## Reusable health snapshot

| Field | Evidence/result |
| --- | --- |
| Snapshot UTC / operator | `<value>` |
| Control plane version/state | `<exact version, ACTIVE state>` |
| OCI-offered next versions / source output ref | `<values, protected reference>` |
| Worker skew result / source output ref | `<supported/unsupported>` |
| Pool IDs, versions, images, sizes, placement | `<values>` |
| Node name, provider ID, private IP, pool, readiness | `<one row/reference per node>` |
| APIs and admission components | `<result>` |
| Platform Deployments/DaemonSets/controllers | `<result>` |
| Non-completed pods / unexpected restarts | `<result>` |
| Longhorn nodes/disks/capacity | `<result>` |
| Five Longhorn volumes and replica counts | `<exact health/placement>` |
| Longhorn engines/replicas/pending operations | `<result>` |
| Argo Applications, health/sync/revisions | `<result>` |
| F5 Service identity/selectors/address/backends | `<result>` |
| HTTP/TLS and Echo | `<endpoint, result>` |
| OpenVPN connection/private reachability | `<result>` |
| Vaultwarden login/read | `<result>` |
| Medusa storefront/backend | `<result>` |
| PostgreSQL/Redis/uploads/persistent read-write | `<result>` |
| Backup Storage Location | `<Available or STOP>` |
| Kopia BackupRepositories | `<namespace, Ready/error>` |
| Evidence references | `<protected paths/checksums>` |

## Backup evidence

These records prove current backup creation and External Backup Store access,
not restoreability.

| Phase | Namespace | Immutable backup name | Created UTC | Included namespaces | Status | Errors | Warnings | Kopia repository | BSL | Evidence ref |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `<baseline/platform/migration/post-removal>` | `staging` | `<name>` | `<UTC>` | `<value>` | `<Completed>` | `0` | `0` | `<Ready>` | `<Available>` | `<ref>` |
| `<phase>` | `vaultwarden` | `<name>` | `<UTC>` | `<value>` | `<Completed>` | `0` | `0` | `<Ready>` | `<Available>` | `<ref>` |
| `<phase>` | `openvpn` | `<name>` | `<UTC>` | `<value>` | `<Completed>` | `0` | `0` | `<Ready>` | `<Available>` | `<ref>` |

## Approval Gate 1 — Starting Baseline

- [ ] Complete health snapshot passes on `ACTIVE` `v1.34.2` and three Ready
  `v1.34.2` workers.
- [ ] APIs/admission and every Shared Platform Service pass.
- [ ] Five Longhorn volumes each have exactly three healthy replicas and no
  pending storage operation.
- [ ] All Applications are Healthy/Synced at recorded revisions.
- [ ] All endpoint and functional checks pass.
- [ ] Fresh backup table passes for all three stateful namespaces.
- [ ] Full Infrastructure and Platform plans show no unexplained drift.
- [ ] State-address plan shows only preservation at the `v1.34.2` map address.

| Approval field | Value |
| --- | --- |
| Evidence snapshot/checksum | `<value>` |
| Bound plan SHA-256 | `<value>` |
| Approver / decision / UTC | `<value>` |
| Action authorization | `<state-address action, name, UTC>` |
| Apply/result reference | `<value>` |
| Follow-up full no-change plan | `<sha256/result>` |

## Shared Platform Service hop records

Copy a row for every hop; attach the service-runbook exit evidence. The next row
does not begin until the current row passes.

| Service | From | To chart/app/plugin | CRD/image set | Plan SHA-256 | Approval UTC | Apply/result | Exit gate | Functional result | Evidence ref |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Longhorn | `<from>` | `<to>` | `<value>` | `<sha>` | `<value>` | `<value>` | `<pass/STOP>` | `<value>` | `<ref>` |
| Velero | `<from>` | `<to>` | `<value>` | `<sha>` | `<value>` | `<value>` | `<pass/STOP>` | `<value>` | `<ref>` |
| cert-manager | `<from>` | `<to>` | `<value>` | `<sha>` | `<value>` | `<value>` | `<pass/STOP>` | `<value>` | `<ref>` |
| F5 NGINX | `<from>` | `<to>` | `<value>` | `<sha>` | `<value>` | `<value>` | `<pass/STOP>` | `<value>` | `<ref>` |
| Argo CD | `<from>` | `<to>` | `<value>` | `<sha>` | `<value>` | `<value>` | `<pass/STOP>` | `<value>` | `<ref>` |

## Approval Gate 2 — Platform Complete

| Field | Value |
| --- | --- |
| Final Longhorn chart/app/CRDs/images | `<value>` |
| Final Velero chart/app/plugin/CRDs/images | `<value>` |
| Final cert-manager chart/app/CRDs | `<value>` |
| Final F5 NGINX chart/app/CRDs and Service/LB identity | `<value>` |
| Final Argo CD chart/app/CRDs and ownership checks | `<value>` |
| Complete post-platform health snapshot | `<checksum/ref>` |
| Fresh backups | `<table rows/ref>` |
| Gate approver / decision / UTC | `<value>` |

## Control-plane hop records and Gates 3–4

| Field | Gate 3: v1.35.2 | Gate 4: v1.36.1 |
| --- | --- | --- |
| Pre-hop control plane/state | `<v1.34.2 ACTIVE>` | `<v1.35.2 ACTIVE>` |
| OCI exact target offered | `<evidence>` | `<evidence>` |
| Temporary v1.34.2 worker skew | `<evidence>` | `<revalidated evidence>` |
| Complete pre-hop health snapshot | `<ref>` | `<ref>` |
| Full plan SHA-256 | `<sha>` | `<sha>` |
| Expected only control-plane effect | `<pass/STOP>` | `<pass/STOP>` |
| Old-pool unchanged | `<pass/STOP>` | `<pass/STOP>` |
| Gate approver / decision / UTC | `<value>` | `<value>` |
| Apply authorization / UTC | `<value>` | `<value>` |
| OCI work request / timestamps/result | `<value>` | `<value>` |
| Exact post-hop version/state | `<v1.35.2 ACTIVE>` | `<v1.36.1 ACTIVE>` |
| Complete post-hop health snapshot | `<ref>` | `<ref>` |
| Incident/forward-repair reference | `<none/value>` | `<none/value>` |

## New worker-pool qualification

| Field | Value |
| --- | --- |
| Full creation-plan SHA-256 and approval | `<value>` |
| Expected add-only effect | `<pass/STOP>` |
| Pool OCID/name/version/size | `<v1.36.1, exactly 3>` |
| Exact image OCID and validated metadata | `<value>` |
| Availability-domain placement and rationale | `<value>` |
| OCI work request/result | `<value>` |
| Three new node identities/readiness | `<value>` |
| Required DaemonSets on every new node | `<value>` |
| Longhorn nodes/disks/capacity | `<value>` |
| Complete health/functional snapshot | `<ref>` |
| Fresh backup evidence | `<ref>` |

## Approval Gate 5 — First Old-Worker Cordon

| Field | Value |
| --- | --- |
| New-pool qualification evidence | `<checksum/ref>` |
| Live old-node name/provider ID/IP/pool mappings | `<value>` |
| Longhorn node/disk/engine/replica placement | `<value>` |
| Ordinary pod/workload placement | `<value>` |
| Stored order still valid | `<yes/no; no = STOP>` |
| Reassessed risk order and rationale, if changed | `<value>` |
| Gate approver / decision / UTC | `<value>` |
| First-worker action authorization / UTC | `<value>` |

## Per-worker migration record

Copy for each old worker in the approved live risk order.

| Field | Value |
| --- | --- |
| Sequence / resolved identity / private IP | `<value>` |
| Placement and risk rationale | `<value>` |
| Current evidence checksum | `<value>` |
| Action approver / UTC | `<value>` |
| Start/end UTC and interruption | `<value>` |
| Longhorn scheduling disable result | `<value>` |
| Cordon/drain/evictions; no force deletion | `<value>` |
| Workload/platform rescheduling | `<value>` |
| Volume/engine/replica before-after placement | `<value>` |
| Exactly three healthy replicas/no pending operation | `<pass/STOP>` |
| Argo/controller/pod/endpoint/LB checks | `<pass/STOP>` |
| HTTP/TLS/Echo/OpenVPN/Vaultwarden/Medusa checks | `<pass/STOP>` |
| Decision: continue / pause / rollback | `<value>` |
| Incident/repair/rollback evidence | `<none/value>` |

## Worker-only rollback record

| Field | Value |
| --- | --- |
| Trigger and UTC | `<value>` |
| Operator/approver | `<value>` |
| Drains stopped | `<result>` |
| New workers cordoned and retained | `<value>` |
| Old-worker scheduling/cordons restored | `<value>` |
| Eviction and detach/reattach sequence | `<value>` |
| Longhorn placement and health | `<value>` |
| Argo/storage/ingress/functional result | `<value>` |
| Control plane retained at v1.36.1 | `<result>` |
| Failed-new-pool evidence preserved | `<ref>` |
| Next reviewed action | `<value>` |

## Approval Gate 6 — Migration Acceptance

- [ ] All ordinary workloads are on new workers.
- [ ] No Longhorn engine or replica remains on an old worker.
- [ ] Three new workers and all required DaemonSets/controllers are ready.
- [ ] Five volumes each have exactly three healthy new-pool replicas and no
  pending operation.
- [ ] All Applications are Healthy/Synced at recorded revisions.
- [ ] All endpoint, ingress, OpenVPN, Vaultwarden, and Medusa checks pass.
- [ ] Fresh post-migration backups/repositories/BSL pass.
- [ ] The approver accepts that old-pool deletion permanently removes worker
  rollback and that restoreability remains unproven.

| Approval field | Value |
| --- | --- |
| Complete evidence checksum/ref | `<value>` |
| Gate approver / decision / UTC | `<value>` |
| Risk-owner acknowledgement / UTC | `<value>` |

## Old-pool retirement

| Field | Protection-removal phase | Destruction-only phase |
| --- | --- | --- |
| Both entries configured | `<yes>` | `<no; only new remains after apply>` |
| Full plan SHA-256 | `<sha>` | `<sha>` |
| Expected effect | `<no live change>` | `<destroy only v1.34.2 pool>` |
| Review result | `<pass/STOP>` | `<pass/STOP>` |
| Action approver / UTC | `<value>` | `<value>` |
| Apply / work request / result | `<value>` | `<value>` |

Post-removal complete health snapshot/checksum: `<value>`

Worker rollback is unavailable from UTC: `<timestamp>`

## Stop and forward-repair log

| UTC | Failed/ambiguous gate | State preserved | Evidence ref | Supported branch | Approval invalidated | Repair authorization | Rerun result |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `<value>` | `<value>` | `<value>` | `<ref>` | `<platform/control-plane/pool/worker/post-retirement>` | `<value>` | `<value>` | `<value>` |

## Final handoff

| Field | Value |
| --- | --- |
| Final control-plane version/state | `<v1.36.1 ACTIVE>` |
| Final worker pool/version/image/placement | `<value>` |
| Final platform versions/CRDs/plugins/images | `<value>` |
| Plans/checksums/applies/work requests index | `<ref>` |
| Service-hop evidence index | `<ref>` |
| Worker-migration evidence index | `<ref>` |
| Functional verification index | `<ref>` |
| Backup/repository/BSL evidence index | `<ref>` |
| Approval index | `<ref>` |
| Post-removal verification | `<ref>` |
| Incidents/forward repairs/open actions | `<value>` |
| Private-artifact modes rechecked | `<result>` |
| Repository free of sensitive artifacts | `<git status/result>` |

Residual risks accepted at handoff:

- [ ] Velero/Kopia restoreability remains unproven; no restore rehearsal occurred.
- [ ] Bounded interruptions were accepted for singleton and `ReadWriteOnce`
  Application Workloads.
- [ ] Worker-only rollback was lost when the old pool was deleted.

| Handoff field | Value |
| --- | --- |
| Evidence owner | `<name>` |
| Receiving owner | `<name>` |
| Acceptance / UTC | `<value>` |
| Upgrade status | `<complete or paused>` |
| If paused, current safe state and next authorized action | `<value>` |
