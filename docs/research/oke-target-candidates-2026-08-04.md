# OKE target candidates and upgrade constraints — 2026-08-04

## Question

Which Kubernetes versions newer than `v1.34.2` are actually available to the production OKE cluster `prod-cluster` in `uk-london-1`, and what upgrade constraints govern them?

## Finding

**The frozen target is `v1.36.1`.** A follow-up read-only OCI `GetClusterOptions` call in `uk-london-1` returned versions through `v1.36.1`, and the actual ACTIVE `v1.34.2` production cluster currently offers `v1.35.0` and `v1.35.2` as its next upgrades. Intersecting the regional OCI result with the separately established Kubernetes 1.36 Shared Platform Service ceiling selects `v1.36.1`.

The supported route starts with `v1.34.2` to `v1.35.2`. After that work request completes, the runbook must query the cluster again and require OCI to offer `v1.36.1` before taking the second control-plane hop. It must abort rather than substitute a different patch release if that offer is absent.

## Evidence

- The repository's Infrastructure State identifies `prod-cluster` as `ocid1.cluster.oc1.uk-london-1.…`, with control-plane version `v1.34.2`; its active blue/green node pool is also `v1.34.2`. This was read directly from the local Terraform state with `jq`, without refreshing or changing state. The desired version is likewise `v1.34.2` in [infra/variables.tf](../../infra/variables.tf#L99).
- The cluster's generated kubeconfig points to the live API endpoint, but a read-only `kubectl version` query could not connect from the sandbox. No Kubernetes object was changed.
- A follow-up read-only `oci ce cluster-options get --cluster-option-id all --region uk-london-1` call returned `v1.33.0`, `v1.33.1`, `v1.33.10`, `v1.34.0`, `v1.34.1`, `v1.34.2`, `v1.35.0`, `v1.35.2`, `v1.36.0`, and `v1.36.1`. `GetClusterOptions` is OCI's authoritative regional API surface for this list: [OCI Container Engine `GetClusterOptions` API](https://docs.oracle.com/en-us/iaas/api/#/en/containerengine/20180222/ClusterOptions/GetClusterOptions).
- A follow-up read-only `oci ce cluster get` call reported the production cluster ACTIVE on `v1.34.2` with `v1.35.0` and `v1.35.2` as its currently available upgrades.
- OCI documents the currently supported OKE versions and lifecycle policy, but that global documentation is not proof that a version is exposed to this particular cluster and region: [Supported Versions of Kubernetes](https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengaboutk8sversions.htm).

## Upgrade constraints that can be fixed now

1. **Use only a version returned by the actual OKE regional API.** OCI's `GetClusterOptions` response is the availability authority; release announcements or global support tables are insufficient for freezing this cluster's target.
2. **Upgrade the control plane before managed node pools.** OCI's documented OKE sequence upgrades the control plane and then node pools: [Upgrading a Kubernetes Cluster](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengupgradingk8scluster.htm).
3. **Do not build a control-plane downgrade into the plan.** OCI's documented workflow is an upgrade path, not a downgrade mechanism; the Wayfinder decision already fixes the upgraded control plane as the rollback boundary. Worker failure is handled by returning workloads to the retained `v1.34.2` pool, provided that pool remains within the target control plane's supported skew.
4. **Use the OCI-offered intermediate minor.** The first control-plane hop is `v1.34.2` to `v1.35.2`. Query the cluster again after that hop and proceed to `v1.36.1` only when OCI offers it.
5. **Keep workers within Kubernetes skew for every hop.** Upstream permits `kubelet` to be no newer than `kube-apiserver` and, in current supported releases, up to three minor versions older, subject to the more restrictive rule of the managed service: [Kubernetes version-skew policy](https://kubernetes.io/releases/version-skew-policy/). The OKE-offered node-pool versions remain controlling.
6. **Treat control-plane maintenance behavior as a verification item, not a zero-impact guarantee.** OCI performs the managed control-plane operation; the approved availability policy permits brief API unavailability but requires zero Application Workload downtime. The runbook must observe OKE work-request completion before advancing to workers.

## Required approval-time evidence

Capture and attach sanitized output from these read-only calls (or their OCI Console equivalents):

```sh
oci ce cluster get --cluster-id <prod-cluster-ocid>
oci ce cluster-options get --cluster-option-id all
oci ce node-pool get --node-pool-id <active-pool-ocid>
```

The evidence must show the region/profile used, current control-plane and worker versions, the exact list of offered Kubernetes versions, and the OCI-offered upgrade path. The August 4, 2026 evidence freezes `v1.36.1` as the target. Repeat these calls as a fail-closed execution preflight to detect any later OCI availability change without automatically chasing a newer release.

## Scope and safety

All checks performed for this report were read-only. No live infrastructure, Kubernetes resource, Terraform state, or Argo CD state was mutated.
