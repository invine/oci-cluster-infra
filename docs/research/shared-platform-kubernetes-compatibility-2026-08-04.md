# Shared Platform Service compatibility with Kubernetes 1.36

Research date: 2026-08-04

## Conclusion

The highest joint Kubernetes ceiling established by the five critical Shared Platform Services is **Kubernetes 1.36**. This is a platform ceiling, not proof that OKE offers 1.36 in `uk-london-1`; the OKE candidate ticket must intersect its result with this one.

The evidence is not equally strong for every service:

| Service | Current configured/live version | Evidence for Kubernetes 1.36 | Required compatibility change |
|---|---|---|---|
| Longhorn | chart/images `1.7.2` | Longhorn 1.12 requires Kubernetes `>=1.25` and publishes no upper bound. Compatibility with 1.36 is therefore an inference from the maintained release's stated minimum, not an explicit tested-versions claim. | Upgrade one minor at a time: latest 1.8.x, 1.9.x, 1.10.x, 1.11.x, then maintained 1.12.x. |
| Velero | chart `7.2.2`; live server/node-agent `1.14.1`; AWS plugin `1.8.2` | Velero 1.18 declares expected compatibility with Kubernetes `1.18-latest`; its published test matrix reaches Kubernetes `1.35.0`, not 1.36. Thus 1.36 is explicitly inside its expected range but is not listed as tested. | Upgrade sequentially 1.14→1.15→1.16→1.17→1.18, applying the CRDs for every step; use the matching chart and AWS plugin (1.18 guidance uses AWS plugin `1.14.0`). |
| cert-manager | chart/images `1.16.1` | cert-manager 1.21 explicitly supports and tests Kubernetes `1.33-1.36`. | Upgrade one minor at a time through 1.17, 1.18, 1.19, 1.20, and 1.21, always using the latest patch; let Helm upgrade its CRDs. |
| F5 NGINX Ingress Controller | chart `1.4.0`; live controller `3.7.0` | Controller `5.5.4` / chart `2.6.4` is tested on Kubernetes `1.29-1.36`. | First patch to controller 3.7.2/chart 1.4.2, then follow the documented 3.x→4.x migration and finish on 5.5.4/chart 2.6.4; apply the release CRDs separately. |
| Argo CD | chart `7.6.12`; live Argo CD `2.12.6` | Argo CD 3.5 is tested on Kubernetes `1.33-1.36`. | Move through the documented 2.12→2.13→2.14→3.0→3.1→3.2→3.3→3.4→3.5 upgrade notes and pin a Helm chart whose `appVersion` is a supported 3.5 patch; update the full installation/CRD set. |

The configured versions come from [`platform/variables.tf`](../../platform/variables.tf) and the component Terraform files. A read-only live pod-image query confirmed that the configured application versions match the running cluster: Longhorn 1.7.2, Velero 1.14.1, cert-manager 1.16.1, NGINX Ingress Controller 3.7.0, and Argo CD 2.12.6.

## Required upgrade shape

Perform these compatibility upgrades while the control plane is still on Kubernetes 1.34. All selected destination releases include 1.34 in their supported/tested range (or, for Longhorn and Velero, their published compatible range). Validate each service before moving to the next, and only then upgrade the OKE control plane. This separates platform failures from the Kubernetes control-plane change.

### Longhorn

Longhorn explicitly rejects skipped minor releases starting with 1.5 and does not support downgrade after a successful upgrade. Therefore `1.7.2` cannot jump directly to 1.12: use the latest patch in every intervening minor and pass the release's pre-upgrade checks at every hop. Before the first hop, take a Longhorn system backup and confirm all volumes/replicas are healthy; the cluster uses the V1 engine, so the documented V2-volume detach caveat is not applicable unless live inspection discovers V2 volumes. No unrelated V2-engine adoption is required. [Longhorn upgrade policy](https://longhorn.io/docs/1.12.0/deploy/upgrade/), [Longhorn 1.12 requirements and manual checks](https://longhorn.io/docs/1.12.0/important-notes/)

### Velero

The repo deliberately sets `upgradeCRDs: false`, so a chart version bump alone is insufficient. Each Velero minor's upgrade guide requires the preceding minor and a CRD update. Plan explicit CRD application and server/node-agent/plugin rollout for 1.15, 1.16, 1.17, and 1.18. Upgrade the AWS object-store plugin from 1.8.2 to the version paired with each server release; the 1.18 guide specifies `velero-plugin-for-aws:v1.14.0`. Update `velero_restore_helper_image` from 1.14.1 to the selected server release and retain both existing restore-action ConfigMaps, which remain supported. The cluster uses Kopia rather than the legacy restic repository path, so the 1.17/1.18 restriction on creating new restic-path backups is not a blocker. Exercise backup/restore after every hop, not only at the end. [Velero compatibility matrix](https://github.com/velero-io/velero#velero-compatibility-matrix), [Velero 1.18 upgrade guide](https://velero.io/docs/v1.18/upgrade-to-1.18/), [Velero 1.18 restore image mapping](https://velero.io/docs/v1.18/restore-reference/), [Velero file-system backup notes](https://velero.io/docs/v1.18/file-system-backup/)

### cert-manager

The installed 1.16 line is EOL and only supports Kubernetes through 1.32. Use the official one-minor-at-a-time path, selecting the latest patch of each line through 1.21. The repo already installs CRDs with the Helm release; update the legacy `installCRDs = true` value to the current `crds.enabled = true` spelling and verify Helm ownership before the first hop so CRDs are upgraded with each chart. The repository's `ClusterIssuer` already uses `cert-manager.io/v1`; no API conversion is indicated. Back up Certificate, Issuer, and ClusterIssuer resources and confirm existing Certificates remain Ready after each hop. [cert-manager supported releases](https://cert-manager.io/docs/releases/), [cert-manager upgrade procedure](https://cert-manager.io/docs/installation/upgrade/)

### F5 NGINX Ingress Controller

The current controller is the F5 `nginx/nginx-ingress` product, not the community ingress-nginx controller. Its documented safe path from 3.x first moves chart 1.4.0/controller 3.7.0 to chart 1.4.2/controller 3.7.2, then performs the 4.0 migration. Preserve the existing Service identity and DaemonSet selectors using the documented `serviceNameOverride`, `controller.name`, and `selectorLabels` migration values so the OCI Load Balancer is not needlessly replaced. The 4.0 migration also requires v1 API conversion for any `GlobalConfiguration`, `Policy`, or `TransportServer` objects and structured logging configuration. Repository inspection found no such custom resources, so this is a live preflight check rather than a planned manifest conversion. Apply CRDs from each target release before upgrading because Helm does not upgrade CRDs from a chart's `crds/` directory. Finish on controller 5.5.4/chart 2.6.4. [NGINX tested-version table](https://docs.nginx.com/nginx-ingress-controller/technical-specifications/), [NGINX upgrade procedure](https://docs.nginx.com/nginx-ingress-controller/install/upgrade/)

### Argo CD

The running 2.12.6 release predates Kubernetes 1.34 support fixes and must move to a maintained 3.5 patch before the control-plane upgrade. Review and satisfy every intervening minor/major upgrade note; apply the whole installation set, including CRDs, rather than changing only the image. Repository inspection found no ApplicationSet cluster generator using the Kubernetes-version auto-label, so the 3.4 label-format break is not currently applicable, but verify live state. Because the bootstrap graph uses server-side apply, use an Argo Helm-chart/CRD upgrade method that updates the static schema and CRDs together, then require all Applications to return `Synced` and `Healthy`. [Argo CD tested Kubernetes versions](https://argo-cd.readthedocs.io/en/release-3.5/operator-manual/tested-kubernetes-versions/), [Argo CD upgrade overview](https://argo-cd.readthedocs.io/en/stable/operator-manual/upgrading/overview/), [Argo CD 3.4 version-format change](https://argo-cd.readthedocs.io/en/stable/operator-manual/upgrading/3.3-3.4/)

## Decision and limits

Use **Kubernetes 1.36** as the Shared Platform Service ceiling. If OKE offers only 1.35, the same destination service families also cover 1.35. Do not claim that Longhorn has published a 1.36 test result or that Velero has tested 1.36: those are the two residual evidence gaps. Close them with the mandatory representative stateful restore rehearsal and a Longhorn volume migration rehearsal before approving the live cluster upgrade. Exact chart patch numbers not explicitly fixed above must be resolved to the latest stable patch available at plan approval, without crossing to another feature family.
