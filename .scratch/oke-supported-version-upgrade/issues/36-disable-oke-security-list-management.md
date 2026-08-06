# 36 — Disable OKE security-list management

**What to build:** Establish Terraform as the sole OCI security-list owner by applying only the prepared NGINX LoadBalancer annotation and proving that the existing ingress path remains healthy before Gate 1 is retried.

Type: task
Blocked by: 35
Status: claimed

- [ ] No Platform State or Live State mutation runs until a human approves the exact saved Platform plan and its SHA-256.
- [ ] The approved full Platform plan changes only the existing NGINX Helm release in place to set OKE security-list management mode to `None`.
- [ ] The plan does not replace the Helm release, Kubernetes Service, or OCI Load Balancer; change Service identity or selectors; change chart or application version; change external addresses, NodePorts, health-check port, or LoadBalancer settings; or affect another Platform resource.
- [ ] Terraform applies the exact approved saved Platform plan; any regenerated plan requires validation and approval again.
- [ ] After apply, the existing LoadBalancer identity and external address, HTTP and HTTPS NodePorts, health-check port, controller readiness, ingress routes, TLS, Echo, Medusa, Vaultwarden, and OpenVPN behavior are verified and recorded.
- [ ] If LoadBalancer or ingress health fails, the previous annotation behavior is restored through a separately reviewed Platform plan, recovery is verified, and Gate 1 remains paused.
- [ ] If the annotation succeeds but the later Infrastructure plan is not approvable, management mode remains `None`, the verified post-change security rules remain intact, and Gate 1 pauses without an Infrastructure apply.
- [ ] Fresh post-change evidence supplies the exact Service ports and security-list rules consumed by the Gate 1 validator. If changing the management mode already removed some or all of the six initially captured redundant rules, the evidence identifies those exact removals and confirms that no different rule changed.
- [ ] No Infrastructure plan, Infrastructure State mutation, targeted Terraform operation, OCI rule mutation outside the approved Platform reconciliation, or unrelated Live State mutation is performed.

## Comments

- 2026-08-06 preparation captured fresh protected Service, controller,
  endpoint, and OCI security-list evidence. The Service remained a LoadBalancer
  with the expected HTTP, HTTPS, and health-check ports; the controller and
  endpoints were 3/3 ready; management mode was unset.
- The first saved full Platform plan was rejected without applying because it
  also proposed updates to Argo CD, cert-manager, Longhorn, and Velero. Those
  diffs came from future-hop compatibility settings being active at the current
  release pins. The configuration now preserves the current release value sets
  and activates those settings only after each service leaves its baseline
  version.
- A replacement full plan proved the intended shape during preparation: one
  in-place NGINX Helm update, zero additions or destructions, and no semantic
  value change beyond the security-rule management annotation. It will be
  regenerated from the reviewed commit before approval; no plan has been
  applied.
