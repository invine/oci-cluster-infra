# Prepare and execute the Longhorn upgrade path

This runbook prepares the Terraform-managed Longhorn Shared Platform Service to
move from `1.7.2` to `1.12.0`. Repository preparation does not authorize a
Terraform apply, Helm action, Kubernetes mutation, engine upgrade, or other
change to Live State. Each live hop requires a separately reviewed full
Terraform plan and explicit human authorization under the production upgrade
runbook.

## Frozen sequence and release contract

Use exactly one row per hop. Never skip, combine, or automatically substitute a
release.

| From | To chart/app | Official destination prechecks | CRD lifecycle |
| --- | --- | --- | --- |
| `1.7.2` | `1.8.2` / `v1.8.2` | Require Kubernetes `>=1.25`, the supported `v1.7.x` source, and the common manual checks below. | The `1.8.2` chart runs its `longhorn-pre-upgrade` hook and upgrades its templated CRDs with the release. |
| `1.8.2` | `1.9.2` / `v1.9.2` | Require Kubernetes `>=1.25`, the supported `v1.8.x` source, and the common manual checks below. | The `1.9.2` chart runs its `longhorn-pre-upgrade` hook and upgrades its templated CRDs with the release. |
| `1.9.2` | `1.10.2` / `v1.10.2` | Require Kubernetes `>=1.25`, the supported `v1.9.x` source, and the common manual checks below. Use the release-required `backing-image-manager:v1.10.2-hotfix-1`; Terraform pins it for this stage. | The `1.10.2` chart runs its `longhorn-pre-upgrade` hook and upgrades its templated CRDs with the release. |
| `1.10.2` | `1.11.3` / `v1.11.3` | Require Kubernetes `>=1.34` because of CSI external-provisioner `v6.3.0`, the supported `v1.10.x` source, and the common manual checks below. | The `1.11.3` chart runs its `longhorn-pre-upgrade` hook and upgrades its templated CRDs with the release. |
| `1.11.3` | `1.12.0` / `v1.12.0` | Require Kubernetes `>=1.25` because of CSI external-snapshotter `v8.2.0`, the supported `v1.11.x` source, and the common manual checks below. | The `1.12.0` chart runs its `longhorn-pre-upgrade` hook and upgrades its templated CRDs with the release. |

The chart/application pairs above are fixed. `platform/variables.tf` rejects any
other chart version. Each upstream chart declares the matching `appVersion`,
contains `templates/crds.yaml`, and enables both
`preUpgradeChecker.jobEnabled` and
`preUpgradeChecker.upgradeVersionCheck`. Because the CRDs are chart templates,
not files in Helm's install-only `crds/` directory, the Terraform-managed Helm
release updates the matching CRDs during every hop. Do not apply CRDs from a
different tag or manage them with a second tool.

The image repository prefix changes with the `1.10.2` chart because that chart
begins prepending its own `docker.io` registry. Terraform preserves the same
effective `docker.io/longhornio/*` image locations on both sides of the boundary
and prevents invalid `docker.io/docker.io/*` image references. This is chart
compatibility handling, not a registry or storage migration.

Review the official notes for the exact destination release immediately before
its hop. Longhorn no longer publishes the older minor manuals on its current
documentation site, so the immutable upstream release pages are the source for
those destinations. Apply the current official upgrade policy and manual checks
at every hop.

- [`v1.8.2` release](https://github.com/longhorn/longhorn/releases/tag/v1.8.2)
- [`v1.9.2` release](https://github.com/longhorn/longhorn/releases/tag/v1.9.2)
- [`v1.10.2` release](https://github.com/longhorn/longhorn/releases/tag/v1.10.2)
- [`v1.11.3` upgrade](https://longhorn.io/docs/1.11.3/deploy/upgrade/), [`v1.11.3` important notes](https://longhorn.io/docs/1.11.3/important-notes/), and [`v1.11.3` release](https://github.com/longhorn/longhorn/releases/tag/v1.11.3)
- [`v1.12.0` upgrade policy and manual checks](https://longhorn.io/docs/1.12.0/deploy/upgrade/), [`v1.12.0` important notes](https://longhorn.io/docs/1.12.0/important-notes/), and [`v1.12.0` release](https://github.com/longhorn/longhorn/releases/tag/v1.12.0)

The official common manual checks are mandatory at every row even when the Helm
hook passes: confirm the default Longhorn StorageClass parameters have not been
changed incompatibly; take a Longhorn system backup; reject every `Faulted`
volume and failed BackingImage; and confirm any V2 volume is detached with its
replicas stopped. This repository imposes a stricter V1-only gate: the presence
of any V2 volume or replica stops this upgrade path instead of authorizing a V2
operation. Recheck the destination release's post-release known-issues link on
the day of execution.

## Before every hop

Record the source and destination releases, current Kubernetes version, exact
Git revision, operator, approver, and evidence timestamp. Then complete all of
the following:

1. Read the destination release notes and any published upgrade page and
   important notes. Confirm the source is the immediately preceding row and the
   cluster satisfies the stated Kubernetes and host requirements.
2. Create and record a successful Longhorn system backup. Confirm no failed
   BackingImage exists and no volume is `Faulted`.
3. Confirm the V2 Data Engine setting is false and every volume uses the V1 data
   engine. If any V2 volume or replica exists, stop; this runbook does not
   authorize detaching it, migrating it, or enabling V2.
4. Establish the complete health baseline in the exit gate below. Every volume
   must already have exactly three healthy replicas, and no rebuild, engine
   upgrade, attachment/detachment, backup/restore, snapshot, expansion, or other
   storage operation may be pending.
5. Change only `longhorn_version` to the next row in `platform.tfvars`. Generate
   a full, saved platform plan through `scripts/terraform-local`; never use
   `-target`. The plan must update only `helm_release.longhorn` to the exact next
   chart. Any Explicit Secret change, unrelated drift, resource replacement, or
   other platform change stops the hop.
6. Record the plan checksum and obtain explicit human authorization for that
   exact plan. A changed plan or failed/stale health check invalidates approval.

The Helm pre-upgrade hook is part of the authorized release update. Preserve it
and capture its result from the Terraform/Helm output and Kubernetes events. A
failed hook or CRD update stops the hop. Do not bypass the hook, patch CRDs by
hand, or assume a generic downgrade is safe.

## Upgrade V1 volume engines after each manager hop

The Terraform apply upgrades the chart, manager, CSI components, supporting
workloads, and CRDs; it does not upgrade existing volume engines. Automatic
engine upgrades remain disabled with
`concurrentAutomaticEngineUpgradePerNodeLimit: 0` so they cannot cross the
approval boundary silently.

After the manager rollout is healthy, record the destination engine image and
the volume-to-workload map. Obtain separate explicit human authorization for
the engine upgrades; this is a Live State mutation not performed by Terraform.
Then follow the destination release's official **Upgrade Engine** procedure for
each healthy V1 volume, one volume at a time:

1. Take and record a current volume backup. Confirm the volume has exactly three
   healthy replicas and no storage operation is pending.
2. If the destination documentation explicitly supports a live engine upgrade
   from the installed source engine and the volume frontend supports it, select
   the volume in the Longhorn UI, choose **Upgrade Engine**, and select the
   destination release's default engine image.
3. Otherwise use the official offline procedure: stop the owning Application
   Workload during its accepted maintenance window, wait for the volume to
   detach, select **Upgrade Engine** and the destination default engine image,
   then resume the workload. For a volume that is not owned by a Kubernetes
   workload, attach it through the Longhorn UI as the official procedure
   requires.
4. Wait for the engine upgrade to finish and temporary engine/replica resources
   to disappear. Require the volume to return to `Healthy`, its engine to use
   the exact destination image, the workload data path to pass read/write
   checks, and exactly three healthy replicas with no rebuild or other storage
   operation pending before starting another volume.

Record whether the live or offline branch was used, the authorization, volume,
old and new engine images, start/end timestamps, interruption, placement, and
result. A failed engine upgrade stops the hop and all later volumes. Do not
change `longhorn_version` again until every V1 volume has passed this procedure
and the complete exit gate below.

## Observable exit gate

Use read-only `kubectl` queries or the Longhorn UI to record the following after
the authorized apply. Names may be listed first with `kubectl -n longhorn-system
get daemonset,deployment,pod`; do not infer health from a single pod list.

- **Managers:** the `longhorn-manager` DaemonSet has equal desired, current,
  ready, available, and updated counts, with one ready manager on every intended
  storage node. Manager logs and events contain no upgrade, webhook, controller,
  or reconciliation failure.
- **CSI components:** the `longhorn-csi-plugin` DaemonSet is fully ready on every
  intended node. The CSI attacher, provisioner, resizer, and snapshotter
  Deployments have all desired replicas updated, ready, and available. The
  `driver.longhorn.io` CSIDriver remains present, and workload PVCs remain Bound
  with expected VolumeAttachments.
- **Supporting workloads:** `longhorn-driver-deployer`, `longhorn-ui`, engine
  image, instance manager, share manager (when used), backing image manager
  (when used), webhook, and recovery backend workloads are ready for the
  destination release. No pod is pending, crash-looping, or using an unexpected
  image.
- **Nodes and disks:** every `nodes.longhorn.io` object reports Ready. Every
  intended node and disk is schedulable, every disk reports Ready and
  Schedulable, and capacity is sufficient for three replicas. There is no disk
  pressure, eviction, or orphan-related error.
- **Volumes:** every `volumes.longhorn.io` object reports `Healthy`; none reports
  `Degraded`, `Faulted`, `Unknown`, attaching, detaching, migrating, expanding,
  restoring, or otherwise transitioning. Each volume specifies exactly three
  replicas and continues to use the V1 data engine.
- **Engines:** every `engines.longhorn.io` object has matching desired and current
  state, no error, and the intended destination engine image after the official
  engine-upgrade step. Attached engines are running; legitimately detached
  engines are stopped. An engine upgrade is a storage operation, so it must
  finish before the gate can pass.
- **Replicas:** every `replicas.longhorn.io` object has matching desired and
  current state, no failure timestamp or error, and belongs to the intended
  destination engine image. Every volume has exactly three nonfailed replicas
  on distinct eligible disks/nodes. Replicas for attached volumes are running;
  stopped replicas are acceptable only for legitimately detached volumes. No
  replica rebuild or removal is pending.
- **CRDs and release:** all Longhorn CRDs are Established with the destination
  chart's served/storage versions, no conversion error is present, and `helm
  list -n longhorn-system` reports the exact chart/application pair from the
  table. The release status is deployed and the pre-upgrade hook succeeded.

Exercise a representative bound PVC through its owning Application Workload and
confirm reads and writes succeed. Repeat the broader application/storage checks
required by the production upgrade evidence contract.

Advance to the next row only when every item above passes simultaneously. A
volume does not pass while it has fewer or more than three healthy replicas, or
while any rebuild or other storage operation is pending. Record the exact
volume-to-engine-to-replica placement as evidence.

## Stop and recovery behavior

On any failed preflight, plan review, Helm hook, CRD update, rollout, engine
upgrade, health check, or data-path check, stop before changing the version
again. Preserve Live State and evidence, diagnose the failed hop, use the
destination release's supported recovery guidance, and rerun the complete gate
after repair. Longhorn does not generally support downgrade after a successful
upgrade, so this runbook never treats changing `longhorn_version` backward as a
rollback procedure.

The platform values explicitly keep `defaultSettings.v2DataEngine: false` and
`persistence.dataEngine: v1`. Do not change those values during this sequence,
and do not combine this work with a storage-engine or data migration.
