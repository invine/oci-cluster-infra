# Select the exact Kubernetes target and hop sequence

Type: grilling
Status: resolved
Blocked by: 01, 02, 03

## Question

Given OKE availability, platform compatibility, and readiness evidence frozen on August 4, 2026, which exact Kubernetes patch release is the highest jointly supported target, and through which control-plane and worker version hops should the approved plan reach it?

## Answer

Lock Kubernetes `v1.36.1` as the exact target frozen on August 4, 2026.

The control plane follows two OCI-gated hops:

1. Upgrade `v1.34.2` to `v1.35.2`, choosing the highest patch OCI currently offers for the required intermediate minor.
2. Wait for the OKE work request to complete, require the cluster to return to `ACTIVE`, repeat the health gates, and query the cluster again.
3. Upgrade `v1.35.2` to `v1.36.1` only if OCI then offers that exact release. If it does not, stop and reopen this decision rather than silently substituting another version.

The worker sequence remains blue/green and does not create an intermediate `v1.35.2` pool:

1. Retain the existing `v1.34.2` pool unchanged through both control-plane hops, subject to an execution-time OKE skew preflight.
2. Once the control plane is `ACTIVE` on `v1.36.1` and all prerequisite Shared Platform Service gates pass, create a new worker pool directly on `v1.36.1` using an exact matching OKE image.
3. Fail closed if OCI does not supply an exact `v1.36.1` worker image; the existing image-selection fallback must not choose an unrelated image.
4. Migrate Application Workloads to the new pool. If worker migration fails, return workloads to the retained `v1.34.2` pool while leaving the control plane on `v1.36.1`.
5. Remove the old pool only after the Migration Acceptance Gate passes.

Required Shared Platform Service compatibility upgrades happen before the first control-plane hop. Their exact release pins and ordering remain owned by [Decide Shared Platform Service upgrade pins and order](10-decide-platform-upgrade-pins-and-order.md).
