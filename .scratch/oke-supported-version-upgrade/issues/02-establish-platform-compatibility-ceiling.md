# Establish the Shared Platform Service compatibility ceiling

Type: research
Status: resolved
Blocked by: none

## Question

For Kubernetes versions newer than `v1.34.2` plausibly available in OKE on August 4, 2026, what is the highest version supported by the cluster's critical Shared Platform Services—Longhorn, Velero, cert-manager, NGINX Ingress Controller, and Argo CD—and which service/chart/CRD changes are required to reach it without unrelated modernization?

## Answer

[Shared Platform Service compatibility with Kubernetes 1.36](../../../docs/research/shared-platform-kubernetes-compatibility-2026-08-04.md) establishes Kubernetes `1.36` as the joint platform ceiling. Reaching it requires staged upgrades from Longhorn 1.7.2 to maintained 1.12.x, Velero 1.14.1 to 1.18.x with sequential CRD/plugin updates, cert-manager 1.16.1 to 1.21.x with Helm-managed CRDs, F5 NGINX Ingress Controller 3.7.0 to 5.5.4/chart 2.6.4 through its documented 3.x migration, and Argo CD 2.12.6 to a supported 3.5.x release with the full CRD/manifest set. The report distinguishes explicit support from tested coverage and inference: cert-manager, NGINX, and Argo CD test 1.36; Velero declares `1.18-latest` compatibility but tests through 1.35; Longhorn publishes a minimum of 1.25 and no upper bound.
