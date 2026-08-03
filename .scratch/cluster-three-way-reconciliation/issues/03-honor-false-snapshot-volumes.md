# Honor explicit false for workload volume snapshots

Status: ready-for-human

## Purpose

Make the Echo, OpenVPN, and Vaultwarden Helm charts preserve an explicit `backup.snapshotVolumes: false` value instead of replacing it with `true`, then publish and reconcile the three workload Schedules through the existing human-attended production controls.

## Problem

Each in-scope chart currently renders:

```yaml
snapshotVolumes: {{ .Values.backup.snapshotVolumes | default true }}
```

Helm treats Boolean `false` as empty for `default`, so all three values files configure `false` while the rendered and live Schedules contain `snapshotVolumes: true`.

The OpenVPN Kopia repository failure investigated during cutover was a separate issue and is resolved. Do not conflate repository recovery with this rendering correction; see issue `01-live-cutover.md` for evidence and final production state.

## Scope

Repository: `/Users/invine/src/oracle-cluster/k8s-charts`

- `echo-chart`
- `openvpn-chart`
- `vaultwarden-chart`

Medusa is explicitly out of scope because its chart comes from `my-medusa-store` and its live Schedule omits this field rather than exhibiting the same local template expression.

## Implementation requirements

- Preserve an explicit Boolean `false` without relying on Helm's `default` function.
- Continue rendering an explicit Boolean `true` when requested.
- Keep existing Schedule names, namespaces, cadence, TTL, storage location, and included namespace unchanged.
- Do not change filesystem-backup pod annotations; OpenVPN and Vaultwarden must continue requesting Kopia filesystem backups.
- Do not change Terraform, Secrets, PVCs, Applications, AppProjects, repository registrations, or the External Backup Store.
- Do not stage or commit unrelated dirty changes.

## Required tests

For Echo, OpenVPN, and Vaultwarden:

1. A default chart render produces `snapshotVolumes: false`.
2. A render with `--set backup.snapshotVolumes=true` produces `snapshotVolumes: true`.
3. `helm lint` passes.
4. Rendered Schedule identity and all non-target behavior remain unchanged.

Add the smallest maintainable regression check supported by the repository rather than relying only on a one-off manual command.

## Human-attended rollout

1. Implement, test, review, and create a focused local `k8s-charts` commit. No production action is implied by local commit creation.
2. Pause for explicit approval before pushing `k8s-charts/main`; the approval must acknowledge the resulting automated Bootstrap Seed reconciliation.
3. Verify Bootstrap becomes Synced/Healthy at the published revision and that no child Application became automated or synced automatically.
4. Review the three child diffs separately. Stop unless each child is Healthy/manual and its only intended change is `spec.template.snapshotVolumes: true -> false` on its existing Schedule:
   - Echo: `velero.io/Schedule velero/echo-app-backup-schedule`
   - OpenVPN: `velero.io/Schedule velero/ovpn-backup-schedule`
   - Vaultwarden: `velero.io/Schedule velero/vaultwarden-backup-schedule`
5. Request a separate explicit approval immediately before each child sync. Sync only the named Schedule at the exact published revision, with pruning disabled and `ApplyOutOfSyncOnly=true`.
6. After each sync, verify the child remains manual/Synced/Healthy, the Schedule remains Enabled with its existing cadence and 30-day TTL, and live `snapshotVolumes` is `false`.

## Stop conditions

- Any in-scope render or live diff changes more than `snapshotVolumes` on the three Schedules.
- Any child Application is automated, unhealthy, or has an unexpected OutOfSync resource.
- Argo proposes pruning any resource.
- A sync would touch a Secret, PVC, workload controller, or resource other than the separately approved Schedule.
- Bootstrap cannot fetch `k8s-charts` or does not become Synced/Healthy after publication.
- Any backup, storage, or workload health regression appears during verification.

Never query, retrieve, or print Secret values.

## Acceptance criteria

- Regression checks prove both explicit `false` and explicit `true` for all three charts.
- The focused chart change passes lint and review and contains no unrelated files.
- The published Bootstrap Seed is Synced/Healthy at the selected revision.
- Echo, OpenVPN, and Vaultwarden remain manual, Synced, and Healthy after three individually approved, Schedule-scoped syncs.
- All three live Schedules are Enabled, retain their prior cadence and TTL, and contain `snapshotVolumes: false`.
- Medusa and all out-of-scope resources are unchanged.
- Evidence and results are appended under this ticket's Comments section.

## Comments

- Created as the non-blocking follow-up identified during the completed live cutover in `01-live-cutover.md`.
- 2026-08-03 local implementation checkpoint:
  - Created focused `k8s-charts/main` commit `eec87a3274e2b753e66939d6b2786fb728d8fb05` (`fix(backup): honor disabled volume snapshots`) from handoff revision `14f61fbda025e09f30f3ecb8165161ec6b93c0e9`; only the three in-scope Schedule templates and `tests/snapshot-volumes.sh` are included.
  - The regression check was observed failing first against Echo's default render, then passed for Echo, OpenVPN, and Vaultwarden after the minimal chart changes. It proves default `false`, explicit `true`, existing Schedule identity and non-target equality between the two renders, and runs `helm lint` for every chart.
  - Full baseline render comparison against `14f61fbda025e09f30f3ecb8165161ec6b93c0e9` passed for all three charts: after normalizing only `spec.template.snapshotVolumes`, default chart output is unchanged; explicit-`true` output is byte-for-byte unchanged. Existing OpenVPN and Vaultwarden `backup.velero.io/backup-volumes` pod annotations remain present.
  - Final local checks passed: `bash -n tests/snapshot-volumes.sh`, `./tests/snapshot-volumes.sh`, `git diff --check`, and focused Helm lint/render assertions. ShellCheck was unavailable locally.
  - Two-axis review against `14f61fbda025e09f30f3ecb8165161ec6b93c0e9` found zero Standards findings and zero implementation Spec findings; no scope creep was identified. Publication and the human-attended rollout remain intentionally pending.
  - The commit has not been pushed. `origin/main` remains at `14f61fbda025e09f30f3ecb8165161ec6b93c0e9`; no production action, Terraform operation, child sync, Secret query, or External Backup Store change was performed during local implementation.
- 2026-08-03 publication and Echo review checkpoint:
  - Operator approved publishing `eec87a3274e2b753e66939d6b2786fb728d8fb05` to `k8s-charts/main`, acknowledging the resulting automated Bootstrap Seed reconciliation. The non-force push succeeded.
  - Bootstrap became Synced/Healthy at exact revision `eec87a3274e2b753e66939d6b2786fb728d8fb05`. Echo, OpenVPN, and Vaultwarden remained Healthy/manual and became OutOfSync at the published revision; their last successful operation revisions remained `14f61fbda025e09f30f3ecb8165161ec6b93c0e9`, proving no child sync ran automatically. Medusa remained Synced/Healthy at its separate repository revision.
  - Echo was reviewed separately. Its only OutOfSync resource is existing `velero.io/Schedule velero/echo-app-backup-schedule`; no resource requires pruning, and all Service, Deployment, and Ingress resources remain Synced/Healthy.
  - Exact published desired/live Schedule comparison shows identical identity and identical complete non-target spec after normalizing the controller's default `skipImmediately: false`. The sole intended change is `spec.template.snapshotVolumes: true -> false`. The live Schedule remains Enabled with daily cadence `0 0 * * *`, TTL `720h0m0s`, storage location `default`, and included namespace `echo`.
  - No Echo operation has been submitted. Paused for Echo-only approval at exact revision `eec87a3274e2b753e66939d6b2786fb728d8fb05`, restricted to that Schedule, with pruning disabled and `ApplyOutOfSyncOnly=true`. No Secret value was queried, and no Terraform or External Backup Store action occurred.
- 2026-08-03 Echo manual-sync verification and Stop:
  - Operator reported completing the Echo sync manually. Echo is now Synced/Healthy and remains manual at exact revision `eec87a3274e2b753e66939d6b2786fb728d8fb05`, with no pending operation, conditions, or OutOfSync resources.
  - The existing Schedule is Enabled with unchanged daily cadence `0 0 * * *`, TTL `720h0m0s`, storage location `default`, and included namespace `echo`; live `spec.template.snapshotVolumes` is `false`.
  - **STOP:** the recorded Argo operation was not Schedule-scoped and did not record `ApplyOutOfSyncOnly=true`. Its operation request contains the exact revision and no pruning request, but no resource restriction or sync options; its results processed the Echo Service, Deployment, and Ingress as `unchanged` and configured the Schedule. This crosses the ticket's stop condition because resources beyond the separately approved Schedule, including a workload controller, were included in the sync operation.
  - Post-operation health is green: the Echo Deployment is fully updated/available with zero unavailable replicas; its pod is Running/Ready with zero restarts. No current workload or backup-Schedule health regression was observed.
  - Paused before reviewing or syncing OpenVPN. No OpenVPN or Vaultwarden operation was submitted, no Secret value was queried, and no Terraform or External Backup Store action occurred.
- 2026-08-03 OpenVPN review and Stop:
  - Operator acknowledged the Echo scope deviation and directed the rollout to proceed to the separate OpenVPN review.
  - The OpenVPN review found that a new manual operation had already completed at exact revision `eec87a3274e2b753e66939d6b2786fb728d8fb05` from `2026-08-03T19:38:02Z` to `2026-08-03T19:38:03Z`, before the required separate OpenVPN approval was requested. OpenVPN is now manual/Synced/Healthy with no pending operation, conditions, OutOfSync resource, or prune requirement.
  - **STOP:** the recorded operation was a full Application sync with no resource restriction and no `ApplyOutOfSyncOnly=true`. It processed the PVC and Service as `unchanged` and configured both the Deployment and `velero.io/Schedule velero/ovpn-backup-schedule`. This crosses the ticket's stop conditions because the operation included a workload controller and resources beyond a separately approved Schedule, and no distinct OpenVPN approval preceded it.
  - Exact published desired/live Schedule comparison now shows identical identity and complete non-target spec; live `spec.template.snapshotVolumes` is `false`. The Schedule is Enabled with daily cadence `0 0 * * *`, TTL `720h0m0s`, storage location `default`, and included namespace `openvpn`.
  - Post-operation health is green: the OpenVPN Deployment is fully updated/available; its pod is Running/Ready with zero restarts; PVC `openvpn/ovpn` remains Bound with storage class `longhorn`, `ReadWriteOnce`, `1Gi`, and a bound volume; the live Kopia filesystem-backup annotation remains `backup.velero.io/backup-volumes: ovpn`; and the OpenVPN BackupRepository remains Ready with no status message.
  - Paused before any Vaultwarden review or operation. No Vaultwarden action was submitted by this session, no Secret value was queried, and no Terraform or External Backup Store action occurred.
- 2026-08-03 Vaultwarden review and Stop:
  - Operator acknowledged the OpenVPN control deviation and directed the rollout to proceed to the separate Vaultwarden review.
  - The Vaultwarden review found that a new manual operation had already completed at exact revision `eec87a3274e2b753e66939d6b2786fb728d8fb05` at `2026-08-03T19:37:55Z`, before the required separate Vaultwarden approval was requested. Vaultwarden is now manual/Synced/Healthy with no pending operation, conditions, OutOfSync resource, or prune requirement.
  - **STOP:** the recorded operation was a full Application sync with no resource restriction and no `ApplyOutOfSyncOnly=true`. It processed the PVC, Service, and Ingress and configured both the Deployment and `velero.io/Schedule velero/vaultwarden-backup-schedule`. This crosses the ticket's stop conditions because the operation included a workload controller and resources beyond a separately approved Schedule, and no distinct Vaultwarden approval preceded it.
  - Exact published desired/live Schedule comparison now shows identical identity and complete non-target spec; live `spec.template.snapshotVolumes` is `false`. The Schedule is Enabled with daily cadence `0 0 * * *`, TTL `720h0m0s`, storage location `default`, and included namespace `vaultwarden`.
  - Post-operation health is green: the Vaultwarden Deployment is fully updated/available; its pod is Running/Ready with zero restarts; PVC `vaultwarden/vaultwarden` remains Bound with storage class `longhorn`, `ReadWriteOnce`, `1Gi`, and a bound volume; the live Kopia filesystem-backup annotation remains `backup.velero.io/backup-volumes: vaultwarden`; and the Vaultwarden BackupRepository remains Ready with no status message.
  - Paused before final verification or ticket closeout. No Secret value was queried, and no Terraform or External Backup Store action occurred.
- 2026-08-04 final read-only verification and closeout:
  - Operator acknowledged the Vaultwarden control deviation and authorized final read-only verification and closeout.
  - Bootstrap is Synced/Healthy at exact published revision `eec87a3274e2b753e66939d6b2786fb728d8fb05`. Echo, OpenVPN, and Vaultwarden are manual/Synced/Healthy at the same revision; Medusa remains manual/Synced/Healthy at its separate repository revision. No Application has a pending operation, condition, OutOfSync resource, or prune requirement.
  - All three in-scope Schedules are Enabled/unpaused in `velero`, retain daily cadence `0 0 * * *`, TTL `720h0m0s`, storage location `default`, and their existing included namespace, and now contain `spec.template.snapshotVolumes: false`.
  - The default BackupStorageLocation is Available with no status message. OpenVPN and Vaultwarden BackupRepositories are Ready with no status message; their Longhorn volumes are attached/healthy. Focused workload, pod, PVC, and filesystem-backup-annotation checks remained green after the manual operations.
  - The latest observed Echo, OpenVPN, and Vaultwarden backups are Completed with zero errors and zero warnings. The latest scheduled runs predate this rollout, so this closeout does not claim a post-change scheduled backup execution; no new Backup was created because the ticket did not authorize one.
  - **Closeout result:** the chart implementation, publication, Bootstrap reconciliation, desired live Schedule state, and current health criteria are achieved. The original procedural criterion requiring three individually approved, Schedule-scoped syncs with `ApplyOutOfSyncOnly=true` is **not met**: all three recorded operations were full Application syncs without the required resource restriction or sync option, and OpenVPN and Vaultwarden ran before their distinct approvals. The operator acknowledged each deviation and authorized continued read-only verification, but the historical control failure cannot be retroactively corrected.
  - No Secret object or value was queried, retrieved, or printed. No Terraform import/apply or External Backup Store modification was performed by this task.
