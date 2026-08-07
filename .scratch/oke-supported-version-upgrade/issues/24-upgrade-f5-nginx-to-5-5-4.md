# 24 — Upgrade F5 NGINX to 5.5.4

**What to build:** Move production F5 NGINX Ingress Controller through its approved migration to application `5.5.4` without replacing the existing Service or Generated OCI Load Balancer.

**Blocked by:** 23 — Upgrade cert-manager to 1.21.1

**Status:** resolved

- [x] Live F5 custom resources are checked for incompatibility before the relevant major hop.
- [ ] Each CRD and Helm hop has a separately reviewed full plan and explicit human authorization. The risk owner prospectively authorized uninterrupted execution through `2.6.4/5.5.4`, so authorization was not bound to the subsequently generated CRD and saved-plan hashes; that stricter process requirement remains an explicitly recorded deviation.
- [x] The approved `1.4.0/3.7.0 → 1.4.2/3.7.2 → 2.0.1/4.0.1 → 2.6.4/5.5.4` sequence is followed exactly.
- [x] Matching F5 CRDs precede each major-version Helm change.
- [x] The Service name, controller name, selector labels, Load Balancer identity, and addresses remain unchanged.
- [x] After every hop, the controller DaemonSet and Load Balancer backends are healthy and every declared HTTP/TLS endpoint succeeds.
- [x] Any replacement, incompatible object, CRD failure, endpoint failure, or unrelated plan effect pauses progression.

## Comments

- Production execution on 2026-08-08 followed the frozen sequence exactly:
  chart/application `1.4.0/3.7.0 → 1.4.2/3.7.2 → 2.0.1/4.0.1 →
  2.6.4/5.5.4`. Each hop used a separate full Platform plan that changed only
  `helm_release.nginx_ingress` in place with zero additions and zero
  destructions. The saved-plan SHA-256 values were
  `19a161bfd884dd93e54a8041a27afee6362767a0b4dfd881d8ff6bec77fc52fa`,
  `09150ab27aafe6dd0d2d2ddc5182337ec55baebefeaeb729db454f1f4da37929`,
  and `c60510f4e03b9e62da85d2a806895eb08c58c2d9a9d3865883ce505b658f0570`.
  Helm recorded the three destination deployments at `2026-08-08 02:20:12`,
  `02:25:46`, and `02:30:26 +0400`. The Codex agent was the operator and the
  human risk owner was the approver; the ordered task transcript retains the
  exact preflight, plan, CRD, apply, rollout, OCI, endpoint, TLS, log, and
  convergence commands and outputs without committing Local Sensitive
  Artifacts.
- The exact destination CRD manifests preceded their Helm hops. Their SHA-256
  values were `8a0b4fb9d612417cfacbef3f0761f6a1675f6e11415bf65874a95eefba08d640`
  for `v3.7.2`, `9ac90a4542ed7f90ea5ccf38cfb43ba25b2f7983ef6a613187eaee35668f781e`
  for `v4.0.1`, and
  `9a79a8233162a61fc16820c17c62ec6c33f2c1666b69814f30603ef4e0b93098`
  for `v5.5.4`. The initial server-side dry run stopped on Helm-owned field
  conflicts. A client-side server dry run and live diff proved that the first
  hop changed only the six CRDs' controller-generator annotation. The matching
  manifests were then server-side applied with conflict takeover under the
  dedicated `ticket-24-f5-upgrade` field manager. Every CRD remained
  Established; the major and final sets serve and store only `v1`.
- Before the 4.0.1 hop, Live State contained no `GlobalConfiguration`,
  `Policy`, or `TransportServer` objects, and the migration-sensitive CRDs had
  only `v1` in `status.storedVersions`. Neither authoritative repository
  contained F5 `k8s.nginx.org/v1alpha1` resources. The chart 2.0.1 render
  retained the Service, DaemonSet, controller, and selector identities and
  replaced numeric log level `1` with structured `info`/`glog` logging.
- Before the 5.5.4 hop, neither Helm values nor the live controller ConfigMap
  contained a custom `main-template`, `ingress-template`,
  `virtualserver-template`, or `transportserver-template`. The chart 2.6.4
  render again retained the required identities and selectors.
- After every hop, Helm reported the exact destination pair as deployed, the
  controller DaemonSet returned to 3/3 desired, updated, ready, and available,
  and all controller EndpointSlice endpoints were Ready. The final controller
  image is `docker.io/nginx/nginx-ingress:5.5.4`; recent destination logs had no
  continuing crash, conversion, configuration, or reconciliation errors.
- The Service remained `nginx-ingress-controller` with UID
  `58c1cac1-b701-4351-8c20-bacf827ce3a0`, ClusterIP `10.96.246.228`, HTTP/HTTPS
  NodePorts `32214/30837`, the original selector labels, and external address
  `130.162.161.246`. The DaemonSet UID remained
  `d0e48d6e-ae92-47db-9bbd-fa0677001127`. The Generated OCI Load Balancer
  remained OCID
  `ocid1.loadbalancer.oc1.uk-london-1.aaaaaaaa3rxawkuznkcxvk7ym34otigaotkzqbu5pzcirvqdve6bci3d4ioa`
  with the same IP, TCP 80/443 listeners, NodePort backends, and `OK` health.
- At every exit gate, Argo CD, echo, and Vaultwarden returned HTTPS 200;
  Medusa storefront returned its expected 307 and API root its expected 404;
  all five HTTP endpoints redirected with 301. Normal TLS verification passed,
  DNS continued to resolve to the original Load Balancer IP, and certificate
  subjects and serials were unchanged.
- The human risk owner instructed the agent to proceed through the final target
  without intermediate approval requests. The CRD and saved-plan hashes were
  generated and mechanically reviewed separately before their mutations, but
  the human authorization was prospective rather than tied to each exact
  artifact. The matching acceptance item therefore intentionally remains open.
- Final full Platform plan SHA-256
  `cb86210146831b87b357460da3d09c6a5d887cc18ff3c5f30010f9e498c1d2da`
  reports `No changes`. Terraform formatting and both root-module validations
  passed, and the full repository test suite passed 12 tests and 54 assertions.

## Answer

F5 NGINX Ingress Controller is upgraded in production through every frozen hop
to chart/application `2.6.4/5.5.4`. Matching CRDs preceded each Helm change,
the 3.x-to-4.x and 5.5 compatibility gates passed, every post-hop health and
endpoint gate passed, and Platform Terraform is converged. The Kubernetes
Service, controller identities and selectors, Generated OCI Load Balancer,
addresses, listeners, backends, and TLS behavior were preserved. The accepted
residual process deviation is prospective rather than exact-artifact-bound
human authorization for the three CRD and saved-plan pairs.
