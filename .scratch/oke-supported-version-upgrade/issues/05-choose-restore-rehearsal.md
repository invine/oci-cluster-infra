# Choose the representative stateful restore rehearsal

Type: grilling
Status: resolved
Blocked by: none

## Question

Which Application Workload and state should the mandatory pre-upgrade Velero restore rehearsal exercise, where should it be restored without affecting production, and what evidence constitutes a successful recovery test?

## Answer

Skip the restore rehearsal entirely. No Application Workload will be restored before the upgrade, and the plan explicitly accepts that Velero/Kopia restoreability remains unproven.

Retain a mandatory backup-only gate immediately before the first disruptive upgrade step:

- create or identify a fresh backup for every stateful Application Workload namespace: `staging`, `vaultwarden`, and `openvpn`;
- require every selected Velero Backup to be `Completed` with zero errors and zero warnings;
- require the corresponding Kopia BackupRepository for each namespace to be `Ready` with no error message;
- require the Velero Backup Storage Location to be available;
- record the immutable backup names, timestamps, included namespaces, and repository status in the operator evidence; and
- stop the upgrade if any backup or repository gate fails.

This gate proves that current backup creation and storage access succeed; it does not prove that Kubernetes objects, Longhorn volume data, or applications can actually be recovered. Worker rollback to the retained `v1.34.2` pool remains the primary migration recovery mechanism.
