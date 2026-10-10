# 05: Stage echo's trusted-header handling safely

**What to build:** Public requests continue to receive normal echo responses
while NGINX is proven to remove or replace caller-supplied identity headers
before the new application starts trusting them. Before shared PROXY activation,
requests have no authoritative client fields rather than a forged or inferred
identity.

**Blocked by:** 03 — Qualify shared-ingress cutover and recovery; 04 — Publish a verified echo release.

**Status:** claimed

- [ ] Review the verified release, trusted networks and Live State readiness
  evidence from the blockers. Obtain authorization for the exact staged Argo
  operations before performing any production synchronization.
- [ ] Confirm shared LB PROXY activation has not already occurred. If the
  observed protocol state differs from the expected starting state, reconcile
  the staging plan against Live State before proceeding.
- [ ] Before staging the corrected Ingress, enable F5 snippets through a
  separately reviewed Terraform plan with LB PROXY still disabled. Confirm
  every ready controller has `-enable-snippets` and the shared-route baseline
  passes. Review who can write Ingress resources because snippets contain raw
  NGINX directives.
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

## Comments

2026-10-10: Read-only preflight found that `echo-app` had already been fully
synchronized by Argo CD user `admin` at 13:47:18–13:47:19 UTC to chart commit
`d256b1860ea751f6a3e28d2662007cb19f96af50`. The operation included the
Ingress and Deployment together, so the required Ingress-first verification
gate was bypassed. The Deployment is ready with `ghcr.io/invine/echo:v0.0.4`
and `TRUSTED_PROXY_CIDRS=10.0.4.0/22`. The shared ingress Service has no
PROXY-v2 annotation; its UID and public IP still match ticket 03. All four
ready F5 pods' generated `nginx -T` output omits the echo virtual server.
Ingress events explain why: F5 rejects the `nginx.org/proxy-set-headers`
annotation because `$` is an invalid character in both proposed header
values. A public HTTPS echo request failed during TLS handshake with
`unrecognized name` and HTTP 000. This is an active echo-route outage; do not
continue to LB PROXY activation. Private evidence is in restricted
`/private/tmp/echo-id-05-evidence/`. The exact sync sequence and annotation
contract need repair and requalification before this ticket can resolve.

2026-10-10: Root cause confirmed against F5 documentation and the live
rejection. `nginx.org/proxy-set-headers` accepts literal header values, so it
cannot carry `$proxy_protocol_addr` or `$proxy_protocol_port`. A local chart
correction uses `nginx.org/location-snippets` for the two NGINX
`proxy_set_header` directives and adds a default-off Terraform switch for
F5's required `-enable-snippets` capability. This is local preparation only.
The owner explicitly requested that production remain unchanged while the fix
is developed; the recovery commit has not been pushed or synced.
