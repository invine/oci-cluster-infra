# 17 — Prepare the F5 NGINX upgrade path

**What to build:** Prepare the F5 NGINX Ingress Controller migration to `5.5.4` while preserving the existing Kubernetes Service and Generated OCI Load Balancer identity.

**Blocked by:** None — can start immediately

**Status:** resolved

- [x] The prepared chart/application sequence is exactly `1.4.0/3.7.0 → 1.4.2/3.7.2 → 2.0.1/4.0.1 → 2.6.4/5.5.4`.
- [x] Matching F5 CRDs are associated with each major-version hop and applied before that live Helm change.
- [x] The 3.x-to-4.x migration values preserve the existing Service name, controller name, selector labels, and OCI Load Balancer identity.
- [x] The procedure checks for incompatible live `GlobalConfiguration`, `Policy`, and `TransportServer` objects before the relevant hop.
- [x] Every hop defines exit checks for the controller DaemonSet, Service identity, Load Balancer addresses/backends, and every declared HTTP/TLS endpoint.
- [x] Terraform formatting and non-mutating validation pass; no ingress, CRD, DNS, or Load Balancer mutation is performed.
