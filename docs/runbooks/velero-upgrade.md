# Prepare and execute the Velero upgrade path

This runbook prepares the Terraform-managed Velero Shared Platform Service to
move from application `1.14.1` to `1.18.1`. Repository preparation does not
authorize a Terraform apply, CRD change, Helm action, backup, or other mutation
to Live State. Each live hop requires separately reviewed evidence and explicit
human authorization under the production upgrade runbook.

## Frozen release sets

Advance exactly one row at a time. Do not skip, combine, or substitute a chart,
application, plugin, or image version.

| Stage | Helm chart | Server and node-agent | Restore helper | AWS plugin |
| --- | --- | --- | --- | --- |
| Current | `7.2.2` | `docker.io/velero/velero:v1.14.1` | `docker.io/velero/velero-restore-helper:v1.14.1` | `docker.io/velero/velero-plugin-for-aws:v1.8.2` |
| 1 | `8.7.2` | `docker.io/velero/velero:v1.15.2` | `docker.io/velero/velero-restore-helper:v1.15.2` | `docker.io/velero/velero-plugin-for-aws:v1.11.1` |
| 2 | `10.1.3` | `docker.io/velero/velero:v1.16.2` | `docker.io/velero/velero-restore-helper:v1.16.2` | `docker.io/velero/velero-plugin-for-aws:v1.12.2` |
| 3 | `11.4.0` | `docker.io/velero/velero:v1.17.1` | `docker.io/velero/velero-restore-helper:v1.17.1` | `docker.io/velero/velero-plugin-for-aws:v1.13.2` |
| 4 | `12.1.0` | `docker.io/velero/velero:v1.18.1` | `docker.io/velero/velero-restore-helper:v1.18.1` | `docker.io/velero/velero-plugin-for-aws:v1.14.2` |

`platform/velero.tf` derives the four images from `velero_version`, and
`platform/variables.tf` rejects versions outside this table. The chart's shared
`image` value pins both the Deployment and node-agent DaemonSet. Preserve
`deployNodeAgent: true`, `snapshotsEnabled: false`, and `upgradeCRDs: false`.

The private bucket remains an External Backup Store. Terraform references its
name, Object Storage namespace, prefix, and credentials but neither
Infrastructure State nor Platform State owns the bucket. Do not add a bucket
resource or import it during these hops. Preserve the repository password: a
different password prevents access to existing Kopia repositories.

## Exact-minor CRDs before Helm

Every destination minor requires its own CRDs before the corresponding Helm
change. `scripts/velero-crds` downloads the exact official destination chart,
verifies its repository-published SHA-256 digest, and renders only that chart's
bundled CRDs. This binds the CRDs to the same chart/application artifact used by
the Helm hop. Rendering is read-only and is the repository's syntax check:

```sh
scripts/velero-crds render 8.7.2 > /tmp/velero-1.15.2-crds.yaml
```

Inspect the rendered manifest, record its SHA-256 checksum, and verify that its
only objects are the 13 Velero CustomResourceDefinitions. Then review current
CRDs and the destination minor's official upgrade guide. Obtain explicit human
approval for the exact chart/application pair, manifest checksum, cluster
context, and CRD change. The apply mode deliberately requires that pair and an
explicit context. Immediately before invoking it, print the current context and
compare it with the context recorded in the approval:

```sh
kubectl config current-context
VELERO_CRD_APPLY_CONFIRM=8.7.2/1.15.2 \
VELERO_CRD_APPLY_CONTEXT="$(kubectl config current-context)" \
scripts/velero-crds apply 8.7.2
```

Repeat with `10.1.3/1.16.2`, `11.4.0/1.17.1`, and `12.1.0/1.18.1` only when
that row becomes current. This command mutates cluster-scoped Live State; never
run it during repository validation or before its explicit authorization.
Confirm every Velero CRD is `Established` and has no schema or conversion error
before planning Helm. A failed or partial CRD apply stops the hop. Do not enable
the chart's CRD upgrade job or apply CRDs from `main`, `latest`, another minor,
or an unrecorded local file.

## One Helm hop

After the destination CRDs pass, change only `velero_version` in
`platform.tfvars` to the matching next chart. Generate a full saved platform
plan through `scripts/terraform-local`; never use `-target`. The plan must
update only the Velero Helm release and the restore-helper image in
`fs-restore-action-config` to the single release set in the table. It must
preserve `change-image-name-config`, must not change Explicit Secret data,
create or manage the External Backup Store, replace another resource, or
include unrelated drift. Record the plan checksum and obtain explicit human
approval for that exact full plan before applying it.

Wait for the Helm release to report `deployed`. Confirm the server Deployment
and node-agent DaemonSet use the exact shared Velero image, the init container
uses the row's AWS plugin, and `fs-restore-action-config` names the row's restore
helper. A failed rollout, unexpected image, or attempt by Helm to upgrade CRDs
stops the hop.

## Observable exit gate after every hop

Capture timestamped, read-only evidence for all of the following before the next
row can begin:

- **Deployment:** the Velero Deployment has all desired replicas updated,
  ready, and available; its server image and reported version match the row.
  Logs and events contain no controller, plugin, repository, or storage error.
- **Node agent:** the node-agent DaemonSet has equal desired, current, updated,
  ready, and available counts on every intended node. Its image matches the
  server image and its logs contain no file-system backup or Kopia error.
- **Release and CRDs:** Helm reports the exact chart/application pair, every
  Velero CRD is `Established`, and no conversion or schema error is present.
- **Backup Storage Location:** the `default` BackupStorageLocation reports
  `Available` and successful validation against the existing External Backup
  Store. Its bucket, prefix, and S3 endpoint remain unchanged.
- **Kopia repositories:** every BackupRepository reports `Ready`, including the
  repositories used by `staging`, `vaultwarden`, and `openvpn`; no maintenance,
  connection, password, or corruption error is present.
- **Fresh backups:** create new, uniquely named backups for `staging`,
  `vaultwarden`, and `openvpn`. Each must reach `Completed` with exactly zero
  errors and zero warnings, and its file-system backup activity must finish.
  Record backup names, start/completion times, repository, storage location,
  item counts, and relevant pod-volume backup results.

Creating the three backups is a Live State and External Backup Store mutation
and requires the hop's explicit authorization. A scheduled backup may be used
only when it is new after the hop and independently satisfies every condition.
Any failed, partial, warning-bearing, missing, or stale backup stops progression.

This gate proves current backup creation and access to the External Backup Store;
it does **not** prove restoreability. Do not run a restore rehearsal, create a
Restore, or claim that any backup is restorable as part of this upgrade path.

## Stop behavior

On any failed CRD, plan, Helm, rollout, image, storage-location, repository, or
backup check, stop before changing the version again. Preserve Live State and
evidence, diagnose the failed hop, follow that destination release's supported
recovery guidance, and rerun the entire failed-hop gate after repair. This
runbook does not assume a generic downgrade path.
