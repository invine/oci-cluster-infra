# Echo client identity

Status: ready-for-agent

Design confirmed: 2026-10-10. This specification synthesizes the confirmed
design, prepared implementation and rollout runbook. Readiness describes the
specification; it does not authorize publishing or production mutations.

## Problem Statement

When an operator sends a request to echo through the public ingress, echo logs
the NGINX connection address rather than the caller's public source address.
The existing forwarded-address headers also contain the private upstream
address, and the forwarded-port header describes the destination port. These
values do not answer who initiated the request or which source port reached
the infrastructure.

The operator needs useful client identity in the existing request logs without
losing the immediate peer needed to debug proxy connections. The result must
remain accurate when public callers submit forged forwarding headers and must
not change echo's response behavior. Because the ingress serves multiple
Application Workloads, activation and recovery must account for their shared
availability and the persistent OCI listener setting.

## Solution

Carry the source IP and, when available, source port observed by the OCI load
balancer through the existing F5 NGINX ingress into echo. Enable matching PROXY
protocol settings on the load balancer and ingress. Have NGINX replace dedicated
identity headers with that transport metadata, then have echo accept those
headers only from configured trusted immediate peers.

Add `clientIp` and optional `clientPort` to existing request logs while retaining
`remoteAddr`. Report the public source reaching OCI; do not attempt to recover
an address or port hidden by NAT or a VPN. Missing or unusable metadata leaves
the relevant client fields absent while the request continues normally.

Deploy through the existing Terraform and Argo CD ownership boundaries during
an agreed maintenance window. Install and verify header replacement before the
app starts trusting it. Preserve the public IP during normal activation and
allow a separately reviewed replacement and explicit DNS update if recovery
requires them.

## User Stories

1. As a cluster operator, I want echo logs to show the public source IP reaching
   OCI, so that I can identify the caller of a diagnostic request.
2. As a cluster operator, I want the client source port recorded when reliable
   metadata provides it, so that I can distinguish client connections.
3. As a cluster operator, I want the destination port excluded from client-port
   attribution, so that a value such as 443 does not mislead my investigation.
4. As a cluster operator, I want `remoteAddr` retained alongside client fields,
   so that I can inspect both the originating connection and the immediate peer.
5. As an echo user, I want GET echo requests to retain their current responses,
   so that existing connectivity checks continue to work.
6. As an echo user, I want POST echo requests to retain their current responses,
   so that existing payload checks continue to work.
7. As an echo user, I want ping requests to retain their current responses,
   so that existing health and connectivity checks remain useful.
8. As a cluster operator, I want client identity on existing missing-message
   and invalid-JSON log paths, so that malformed requests remain traceable.
9. As a cluster operator, I want existing log levels preserved, so that enabling
   client identity does not unexpectedly change normal logging volume.
10. As a caller behind NAT or a VPN, I want logs to represent the source visible
    at OCI, so that operators understand the limits of the reported identity.
11. As a cluster operator, I want valid IPv4 and IPv6 identity metadata handled,
    so that logging can represent either address family when supplied.
12. As a cluster operator, I want equivalent IPv4-mapped addresses normalized,
    so that trust checks and log searches use a consistent address form.
13. As a cluster operator, I want absent identity metadata to produce absent
    client fields, so that missing information is not replaced by a proxy IP.
14. As an echo user, I want malformed identity metadata to leave the request
    functional, so that diagnostic logging cannot break the echo response.
15. As a cluster operator, I want duplicate or chained IP values rejected for
    attribution, so that the app does not guess which address to trust.
16. As a cluster operator, I want a valid client IP retained when only the port
    is unavailable or invalid, so that optional port data does not hide the IP.
17. As a cluster operator, I want public callers' identity headers overwritten,
    so that callers cannot choose the authoritative address in echo's logs.
18. As a cluster operator, I want ordinary forwarding headers excluded as
    fallback identity sources, so that spoofed chains cannot bypass validation.
19. As an application maintainer, I want forwarded identity disabled by default,
    so that an unconfigured deployment does not trust arbitrary callers.
20. As an application maintainer, I want trust configured through explicit
    immediate-peer CIDRs, so that the accepted source networks are reviewable.
21. As a cluster operator, I want the trust of internal subnet callers stated
    explicitly, so that diagnostic identity is not mistaken for authentication.
22. As an application maintainer, I want invalid or catch-all trust configuration
    rejected, so that configuration mistakes cannot silently enable global trust.
23. As a platform maintainer, I want shared-ingress changes owned by Terraform,
    so that subsequent reconciliation preserves the intended protocol settings.
24. As an application maintainer, I want echo changes delivered through Argo CD,
    so that the Application Workload retains its existing lifecycle owner.
25. As a platform maintainer, I want OCI security-list ownership preserved,
    so that this feature does not introduce competing rule managers.
26. As a release operator, I want the image digest and ARM64 availability verified
    before deploying its pin, so that the rollout does not depend on a missing image.
27. As a release operator, I want NGINX's header replacement verified before
    enabling app trust, so that the rollout has no header-spoofing window.
28. As a release operator, I want both Argo sync stages to use the same reviewed
    revision, so that unrelated changes cannot enter between stages.
29. As a platform operator, I want LB and ingress settings changed together during
    planned maintenance, so that any protocol mismatch is contained and observable.
30. As a platform operator, I want the normal plan to preserve Service identity
    and the public IP, so that existing endpoints keep their addresses.
31. As a platform operator, I want direct administrative access during cutover,
    so that I can recover even when the public ingress is unavailable.
32. As a platform operator, I want all shared HTTP, TLS and websocket routes
    checked before and after activation, so that echo improvements do not hide
    regressions in other Application Workloads.
33. As a platform operator, I want recovery to respect OCI's retained PROXY
    setting, so that reverting app configuration does not break the shared ingress.
34. As a platform operator, I want replacement recovery to include explicit DNS
    updates and verification, so that users can reach a replacement public IP.
35. As a reviewer, I want public-request evidence to confirm the expected source
    address and spoof resistance, so that local test success is not mistaken for
    production acceptance.
36. As a reviewer, I want Local Sensitive Artifacts kept private and outside Git,
    so that saved plans and operational evidence do not disclose credentials.

## Implementation Decisions

- **Ownership:** Terraform manages the F5 ingress Shared Platform Service and
  its parent LoadBalancer Service. The controller-created OCI load balancer
  remains a Generated Resource, without a second Terraform resource owner.
  Argo CD manages echo's Application Workload, including its Ingress and
  Deployment. Terraform remains the exclusive owner of OCI security lists;
  controller security-rule management remains disabled.
- **Controller family and qualification:** use F5 NGINX Ingress Controller,
  not community ingress-nginx settings. The prepared change is qualified on
  Helm chart 2.6.4 and controller 5.5.4. Activation requires this qualified pair
  and must not be combined with a controller version upgrade.
- **Transport contract:** enable OCI PROXY protocol v2 and matching F5 PROXY
  listeners as one intended configuration change. Configure F5 real-IP
  processing to use PROXY metadata with explicit trusted LB source CIDRs and
  recursive address processing disabled. Preserve `externalTrafficPolicy: Local`.
- **Explicit activation:** platform activation is opt-in through
  `nginx_proxy_protocol_enabled`; `nginx_lb_trusted_cidrs` must be populated with
  valid CIDRs having nonzero prefix lengths. Persist approved settings before
  applying so future full plans retain the enabled state.
- **Deployment trust values:** the prepared LB trust range is `10.0.8.0/24` and
  the prepared app immediate-peer trust range is `10.0.4.0/22`. Confirm both
  against Live State before deployment. These are deployment configuration,
  not hard-coded assumptions inside the application.
- **Ingress-to-app interface:** overwrite `X-Echo-Client-IP` from
  `$proxy_protocol_addr` and `X-Echo-Client-Port` from `$proxy_protocol_port`
  through the F5 `nginx.org/location-snippets` annotation. The F5
  `nginx.org/proxy-set-headers` validator rejects `$` in a header value and
  removed the echo route during the first staging attempt. Enable F5 snippets
  through a separate reviewed controller change before syncing this Ingress.
  Empty transport metadata must remove these headers, including caller-supplied
  values. Verify the generated configuration on every ready ingress instance.
- **Application trust interface:** `TRUSTED_PROXY_CIDRS` is a comma-separated
  list of explicitly trusted immediate-peer networks. The default trusts no
  forwarded identity. Invalid prefixes and catch-all trust are rejected rather
  than silently broadening the trust boundary.
- **Trust boundary:** every caller in the configured internal networks is
  trusted. The feature does not authenticate individual ingress pods or defend
  against a malicious caller within those networks. Header values from an
  untrusted immediate peer must not populate authoritative client fields.
- **Log contract:** retain the existing `remoteAddr` value. Add `clientIp` as a
  validated address string and `clientPort` as an optional integer from 1 through
  65535. Normalize IPv4-mapped addresses for comparison and reporting. Do not
  replace connection-peer fields or change existing response bodies or log levels.
- **Validation and fallback:** require exactly one valid IP value; ambiguous
  lists, duplicates, malformed, scoped, unspecified or multicast addresses are
  not attributable identity. Missing or invalid IP metadata omits both client
  fields. Once IP metadata is valid, missing, duplicate, malformed or out-of-range
  port metadata omits only `clientPort`. Requests continue normally.
- **No alternate header inference:** do not derive authoritative identity from
  `Forwarded`, `X-Forwarded-For`, `X-Real-IP` or `X-Forwarded-Port`. Retained raw
  request headers are diagnostic input, not an assertion of trusted identity.
- **Application integration:** use the existing HTTP handler and request-logging
  boundary to attach client fields to the existing GET, POST, ping and warning
  log paths. No response schema, endpoint or database schema change is needed.
- **Chart contract:** app identity consumption is opt-in through
  `clientIdentity.enabled`; enabling it requires `clientIdentity.trustedProxyCidrs`.
  The prepared Application uses the existing debug logging setting.
- **Release contract:** the prepared image pin is `ghcr.io/invine/echo:v0.0.4`.
  Publish the reviewed source and verify the immutable release's digest and
  Linux ARM64 availability before merging or synchronizing the deployment pin.
  If the tag is occupied by another release, choose and review a new tag rather
  than overwriting it.
- **Argo sequencing:** first enable F5 snippets through a reviewed Terraform
  plan while OCI PROXY remains disabled, and verify all ready controller pods.
  After the Bootstrap Seed reconciles the reviewed child declaration,
  selectively sync echo's Ingress first. Confirm NGINX accepts and installs
  both header replacements before syncing the Deployment. Both Argo stages
  must use the same reviewed chart revision. Before PROXY activation, forged
  headers must yield no authoritative client fields.
- **Platform rollout:** capture actual listeners, health-check behavior,
  controller configuration, Service identity and all served endpoints. Produce
  a fresh full Terraform plan with the persisted settings. The expected normal
  change is one in-place ingress Helm update; reject unrelated resource changes,
  Explicit Secret changes, Service replacement or DNS actions.
- **Maintenance and health:** LB reconciliation and NGINX reloads are not atomic.
  A short planned shared-ingress interruption is accepted. Dedicated controller
  health endpoints and OCI backend checks must remain usable. Keep an
  administrative path that does not depend on the shared public ingress.
- **Recovery:** OCI retains its enabled PROXY setting when the annotation is
  removed or emptied. Disabling the platform flag or restoring old Helm values
  is not a valid routine rollback on that LB. For an echo-only failure, recover
  the app while keeping LB and ingress protocol settings aligned. For shared
  traffic failure, prefer fixing the failing side while retaining that alignment.
- **Replacement and DNS:** if forward recovery is not viable, prepare and review
  a separate Service/LB replacement procedure. A changed public IP is allowed
  for recovery, with explicit DNS update and verification. The existing DuckDNS
  updater does not rerun merely because the LB IP changes. Do not replace the
  entire ingress Helm release simply to replace its Service.
- **Evidence and authorization:** preserve the reviewed release identifiers,
  plan checksum, endpoint baseline and acceptance results. Treat sensitive
  evidence as Local Sensitive Artifacts. Specification readiness and the user's
  acceptance of the design do not by themselves authorize production mutations.

## Testing Decisions

- **Primary seam:** use the already-agreed request-to-log boundary: send a
  request through the ingress path and observe the HTTP response and echo's
  emitted log fields. This is the highest useful feature seam. Favor it over
  tests coupled to parsing helpers, logger context keys or internal call order.
  Reuse the existing server/handler interfaces; no new public test API is needed.
- **Local integration at that seam:** run the matching F5 NGINX image against
  the built echo binary, supplying real PROXY frames in place of the OCI edge.
  Assert the supplied source identity, unchanged immediate peer and unchanged
  response. Exercise PROXY v2, existing v1 compatibility, IPv4/IPv6 metadata,
  forged duplicate HTTP headers, UNKNOWN metadata, ordinary pre-PROXY HTTP and
  an unavailable source port.
- **Focused application cases:** use the existing HTTP test request/response
  boundary and capture structured logs. Cover trusted and untrusted peers,
  default-disabled trust, invalid trust configuration, normalized mapped IPv4,
  absent/malformed/duplicate address metadata and optional-port failures. Check
  that successful and warning log paths satisfy the same observable contract.
- **Good assertions:** assert the exact authoritative fields, absent fields
  where evidence is insufficient, preserved `remoteAddr`, and established
  response behavior. Do not assert private helper names or duplicate the parser's
  implementation in test expectations. Public-header spoofing tests must vary
  caller-supplied headers independently of the PROXY metadata.
- **Deployment contract checks:** render the real echo Application parameters
  and F5 before/after values. Verify an enabled deployment has its expected
  image, trust configuration and dedicated header replacement, while defaults
  do not enable app trust and missing required trust fails validation. Confirm
  the F5 diff preserves resource identity and changes only the intended Service
  annotation and native ConfigMap entries.
- **Plan validation:** use Terraform validation and a full read-only plan to
  establish the actual proposed resource actions. Local chart rendering does
  not prove OCI listener reconciliation, Service preservation in Live State or
  successful production traffic. Do not use a targeted plan as substitute evidence.
- **Production acceptance at the same seam:** from an external client with an
  independently known public source, send labelled GET, POST, ping and warning-
  path requests. The logs must contain that source instead of either proxy
  address or a forged header value. Retain `remoteAddr`. Corroborate a reported
  source port at the public-client/edge boundary where possible; a port chosen
  behind NAT is not independent proof of the port reaching OCI.
- **Shared-service acceptance:** rerun the recorded HTTP, TLS, authentication,
  websocket and relevant ACME route baseline for all served workloads. Inspect
  actual OCI listener/backend health and every ready NGINX instance. A Ready
  pod, successful TCP connect or successful Helm operation alone is insufficient.
- **Prior art and reuse:** extend the prepared Go handler/log tests and the
  existing isolated F5-to-echo harness. Reuse Helm rendering, full Terraform
  planning and shared-ingress endpoint checks already used by the platform
  upgrade runbook. The infrastructure's existing plan-validator tests are prior
  art for verifying observable plan contracts; their worker-upgrade conditions
  should not be copied into this feature.
- **Verification scope:** Go tests with the race detector, static checks, the
  ARM64 build, Helm validation and the isolated proxy test have already passed
  during preparation. Preserve that evidence and rerun relevant checks when
  code or configuration changes. Production acceptance remains outstanding.

## Out of Scope

- Recovering an end-device address or source port hidden by NAT, VPNs or other
  intermediaries before OCI.
- Requiring a client source port when reliable metadata is unavailable.
- Treating client-address logs as authenticated identity or protecting against
  malicious callers inside the explicitly trusted internal networks.
- Installing a NetworkPolicy enforcement engine, introducing authenticated
  ingress-to-app transport or redesigning the cluster's security lists.
- Introducing new echo endpoints, changing responses, adding a database,
  changing general logging levels or redesigning raw-header logging.
- Replacing the shared ingress with a dedicated echo entry path, migrating to
  another LB type or upgrading the ingress controller as part of activation.
- Guaranteeing uninterrupted shared-ingress service or an unchanged public IP
  during exceptional replacement recovery.
- Automatically replacing the Service/LB, changing DNS on every IP update or
  modifying client-identity handling in other Application Workloads.
- Publishing images, merging changes, synchronizing Applications, applying
  Terraform or deleting live resources merely because this spec is marked ready.

## Further Notes

The user confirmed the public-source interpretation, best-effort port, additive
log fields, shared-ingress scope, planned maintenance, replacement-IP recovery,
internal trust boundary and missing-metadata fallback. This specification
records those decisions without reopening the interview.

Implementation has been prepared locally across the echo source, application
charts and Terraform configuration. No production resource was changed during
that preparation. The preview platform plan showed zero additions, one in-place
update and zero deletions; it used temporary activation overrides. Activation
is not yet persisted in the local deployment settings, and the new image was
not published by this work.

Remaining execution consists of reviewing/publishing the immutable release,
verifying actual OCI listeners and trust ranges, performing the staged Argo
syncs, generating and approving a fresh full platform plan, and passing the
production acceptance checks during the agreed maintenance window. Local
success must not be reported as a completed production fix.

- [Rollout and recovery runbook](../../docs/runbooks/echo-client-identity.md)
- [Recorded local validation](validation.md)
- [Release and rollout handoff](issues/01-publish-and-roll-out.md)
- [Shared Platform Service and Application Workload ownership ADR](../../docs/adr/0001-terraform-platform-argo-workloads.md)
- [Exclusive Terraform ownership of OCI security lists ADR](../../docs/adr/0005-terraform-owns-oci-security-lists.md)

The separate release/rollout handoff remains `ready-for-human` because it
contains outstanding production authorization. This spec's `ready-for-agent`
status records a complete, actionable specification rather than changing that
authorization boundary.
