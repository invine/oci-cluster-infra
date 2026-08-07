# 36 — Disable OKE security-list management

**What to build:** Establish Terraform as the sole OCI security-list owner by applying only the prepared NGINX LoadBalancer annotation and proving that the existing ingress path remains healthy before Gate 1 is retried.

Type: task
Blocked by: 35
Status: resolved

- [x] No Platform State or Live State mutation runs until a human approves the exact saved Platform plan and its SHA-256.
- [x] The approved full Platform plan changes only the existing NGINX Helm release in place to set OKE security-list management mode to `None`.
- [x] The plan does not replace the Helm release, Kubernetes Service, or OCI Load Balancer; change Service identity or selectors; change chart or application version; change external addresses, NodePorts, health-check port, or LoadBalancer settings; or affect another Platform resource.
- [x] Terraform applies the exact approved saved Platform plan; any regenerated plan requires validation and approval again.
- [x] After apply, the existing LoadBalancer identity and external address, HTTP and HTTPS NodePorts, health-check port, controller readiness, ingress routes, TLS, Echo, Medusa, Vaultwarden, and OpenVPN behavior are verified and recorded.
- [x] If LoadBalancer or ingress health fails, the previous annotation behavior is restored through a separately reviewed Platform plan, recovery is verified, and Gate 1 remains paused.
- [x] If the annotation succeeds but the later Infrastructure plan is not approvable, management mode remains `None`, the verified post-change security rules remain intact, and Gate 1 pauses without an Infrastructure apply.
- [x] Fresh post-change evidence supplies the exact Service ports and security-list rules consumed by the Gate 1 validator. If changing the management mode already removed some or all of the six initially captured redundant rules, the evidence identifies those exact removals and confirms that no different rule changed.
- [x] No Infrastructure plan, Infrastructure State mutation, targeted Terraform operation, OCI rule mutation outside the approved Platform reconciliation, or unrelated Live State mutation is performed.

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
- 2026-08-06T21:08:06Z execution used configuration revision `d737f6c`. The
  explicitly approved saved plan SHA-256 was
  `e3e79fa40a7f97b86028dd5f3e20bb5059d7cb1f51e4fb66b515e00b35a1022e`:
  zero additions, one in-place NGINX Helm update, zero destructions, and only
  the management annotation changed semantically. The same hash was verified
  immediately before applying that exact artifact.
- The protected apply transcript confirms completion with zero additions, one
  change, and zero destructions. Independent outcome checks found no state
  lock, Platform State recorded `None`, the live Service recorded `None`, and
  the subsequent full Platform plan was empty (saved-plan SHA-256
  `9fd8e73467789a90404b97bf60c90150c675106f53b87dd059bd4220f4994c6b`).
- Post-change comparison proved the Service UID, selectors, type, frontend and
  node ports, health-check port, LoadBalancer address, and every other
  annotation unchanged. The controller and ingress endpoints remained 3/3
  ready. Both live OCI security-list evidence files were byte-for-byte
  unchanged from their pre-apply captures.
- All five HTTPS ingress routes returned HTTP 200 with successful certificate
  verification; all five Argo Applications were Healthy/Synced and no running
  pod was unready. An existing OpenVPN credential completed an authenticated
  external peer connection against a current LoadBalancer address. Protected
  evidence is under `/private/tmp/oke-ticket36-20260807.FHnCqj` with directory
  mode `0700` and file mode `0600`.

## Answer

Terraform is now the exclusive OCI security-list owner. The NGINX LoadBalancer
Service declares management mode `None`; the exact approved Platform plan's
execution and resulting state were confirmed; all identity and functional
checks passed; security-list contents did not change during the prerequisite;
and the follow-up full Platform plan is empty. Ticket 20 may refresh Gate 1
evidence and generate its independently approved Infrastructure plan.
