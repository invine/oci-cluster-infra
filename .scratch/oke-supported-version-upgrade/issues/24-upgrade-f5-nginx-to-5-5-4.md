# 24 — Upgrade F5 NGINX to 5.5.4

**What to build:** Move production F5 NGINX Ingress Controller through its approved migration to application `5.5.4` without replacing the existing Service or Generated OCI Load Balancer.

**Blocked by:** 23 — Upgrade cert-manager to 1.21.1

**Status:** ready-for-human

- [ ] Live F5 custom resources are checked for incompatibility before the relevant major hop.
- [ ] Each CRD and Helm hop has a separately reviewed full plan and explicit human authorization.
- [ ] The approved `1.4.0/3.7.0 → 1.4.2/3.7.2 → 2.0.1/4.0.1 → 2.6.4/5.5.4` sequence is followed exactly.
- [ ] Matching F5 CRDs precede each major-version Helm change.
- [ ] The Service name, controller name, selector labels, Load Balancer identity, and addresses remain unchanged.
- [ ] After every hop, the controller DaemonSet and Load Balancer backends are healthy and every declared HTTP/TLS endpoint succeeds.
- [ ] Any replacement, incompatible object, CRD failure, endpoint failure, or unrelated plan effect pauses progression.
