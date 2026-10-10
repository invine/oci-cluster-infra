# 05: Stage echo's trusted-header handling safely

**What to build:** Public requests continue to receive normal echo responses
while NGINX is proven to remove or replace caller-supplied identity headers
before the new application starts trusting them. Before shared PROXY activation,
requests have no authoritative client fields rather than a forged or inferred
identity.

**Blocked by:** 03 — Qualify shared-ingress cutover and recovery; 04 — Publish a verified echo release.

**Status:** ready-for-agent

- [ ] Review the verified release, trusted networks and Live State readiness
  evidence from the blockers. Obtain authorization for the exact staged Argo
  operations before performing any production synchronization.
- [ ] Confirm shared LB PROXY activation has not already occurred. If the
  observed protocol state differs from the expected starting state, reconcile
  the staging plan against Live State before proceeding.
- [ ] Resolve the reviewed chart commit and keep both sync stages bound to that
  same revision. Verify the Bootstrap Seed's child declaration identifies the
  intended release without automatically synchronizing the workload.
- [ ] Selectively synchronize only echo's Ingress through Argo CD first. On every
  ready ingress instance, verify generated NGINX configuration has exactly the
  required dedicated IP/port header replacements and no conflicting override.
  Confirm the controller accepted the annotation without validation/reload errors.
- [ ] Do not enable app header consumption until every ready ingress instance
  passes that check; an Ingress address or a healthy pod alone is insufficient.
- [ ] Synchronize the full echo Application at the same reviewed revision and
  verify its deployed image and trusted-peer configuration match the release
  package. Wait for a healthy Deployment while preserving existing responses.
- [ ] Send labelled public requests with forged and duplicate dedicated headers
  and ordinary forwarding headers before PROXY activation. Verify authoritative
  client fields are absent, `remoteAddr` is preserved and the responses remain
  unchanged. Retained raw diagnostic headers are not treated as authoritative.
- [ ] Verify the baseline echo GET, POST and ping behavior and check that the
  staging change did not regress the affected shared-ingress routes.
- [ ] Record the exact deployed revision, generated-configuration evidence and
  request/log results for ticket 06. Do not enable LB PROXY protocol, apply
  platform changes or update DNS in this ticket.
