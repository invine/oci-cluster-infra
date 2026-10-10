# 02: Qualify the complete client-identity path

**What to build:** A verified path from LB transport metadata through F5 NGINX
to echo's existing request logs, giving operators an accurate client IP and an
optional source port without losing the immediate peer or changing responses.
Qualify the implementation already prepared across the three repositories;
reuse it and its matching validation evidence, and fix only demonstrated gaps.

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] Review the prepared implementation against the confirmed echo client
  identity specification and identify the exact source revisions or working-tree
  snapshots being qualified. Preserve unrelated user changes.
- [x] Exercise the existing request-to-log boundary through the matching F5
  NGINX image and built echo binary using real PROXY v2 metadata. Verify IPv4,
  IPv6 and existing v1 compatibility without introducing a new public test API.
- [x] Existing GET, POST, ping, missing-message and invalid-JSON paths retain
  their response behavior and log levels. Their logs retain the connection's
  `remoteAddr` and add a validated `clientIp` plus optional numeric `clientPort`.
- [x] The source port is accepted only in the range 1–65535 and is never inferred
  from a destination-port header. Invalid or unavailable port metadata omits
  only the port when the IP remains valid.
- [x] Missing, malformed, duplicate, chained, scoped, unspecified or multicast
  IP metadata omits both client fields without rejecting the request. Verify
  IPv4-mapped normalization and trust checks as externally observable behavior.
- [x] Forged public HTTP identity headers, including duplicates, cannot override
  PROXY metadata. Empty PROXY metadata removes dedicated headers rather than
  passing caller-supplied values through. Ordinary forwarding headers cannot
  become an alternate authoritative identity source.
- [x] App trust defaults to disabled and accepts metadata only from configured
  immediate-peer CIDRs. Invalid or catch-all trust is rejected. Document that
  every caller within the configured internal networks is trusted.
- [x] Render the active echo Application parameters and F5 before/after values.
  Verify the dedicated header overwrites, required trusted networks, opt-in
  behavior and native F5 configuration. Enabling app identity without its trust
  configuration must fail validation.
- [x] The rendered platform change preserves Service identity, selectors,
  traffic policy and controller DaemonSet, adding only the intended Service
  PROXY annotation and native ConfigMap settings. Preserve Terraform and Argo CD
  ownership and exclusive Terraform ownership of OCI security lists.
- [x] Record passing Go tests with the race detector, static checks, ARM64 build,
  Helm validation and the isolated proxy test for the qualified implementation.
  Reuse existing evidence when it matches unchanged inputs; rerun checks affected
  by any fixes. Keep sensitive evidence as Local Sensitive Artifacts.
- [x] Hand off the qualified source snapshots and any remaining operational
  assumptions to the release and cutover tickets. Completion does not claim
  production acceptance or authorize publication or deployment.

## Answer

Qualified the prepared source snapshots without changing implementation code:

- Infrastructure: `8ce44946a64d6fc5f70d121716f094e47f54821a`.
- Application charts: `d256b1860ea751f6a3e28d2662007cb19f96af50`.
- Echo: `81bc06dfb5081b748f33adc1f5b01b939e06b60d`.

The existing request-to-log tests cover the trusted and untrusted peers,
validation and fallback cases, all GET/POST/ping and warning paths, response
bodies, and retained `remoteAddr`. Fresh `go test -race ./...`, `go vet ./...`,
and Linux ARM64 build passed on the echo revision above. A fresh isolated replay
with `nginx/nginx-ingress:5.5.4` at digest
`sha256:379143154a02d16e4b7d56ad505636bdf73b2c190825ef023c803958ba5eb57c`
passed PROXY v1, v2 IPv4 and IPv6, duplicate forged HTTP headers, UNKNOWN,
ordinary pre-PROXY HTTP, and zero source port. Docker networking was disabled;
the test fixture was mounted read-only.

Fresh echo Helm lint and default, enabled, and active Application renders
passed. Enabling identity without trusted CIDRs failed rendering as intended.
The active render exactly matched the saved render in
[`../validation.md`](../validation.md). Fresh F5 chart 2.6.4 renders exactly
matched the saved before/after artifacts. Their only rendered difference is
the Service PROXY-v2 annotation and four native ConfigMap settings; Service
identity, selectors, `externalTrafficPolicy: Local`, controller DaemonSet, and
disabled controller security-rule management remain intact. Terraform
formatting and validation passed. The saved full read-only plan reports only
an in-place `helm_release.nginx_ingress` update plus a dependent Service data
read; it used temporary activation overrides and preceded a validation-only
CIDR check tightening, so release must regenerate the full plan after approved
settings are persisted.

Sensitive plan and proxy fixtures remain ignored Local Sensitive Artifacts in
the original checkout's `.scratch/echo-client-identity/evidence/` directory;
the saved plan SHA-256 is recorded in [`../validation.md`](../validation.md).
The source and test evidence establish local behavior, not Live State or
production acceptance. Ticket 04 must publish and verify the immutable echo
release and ARM64 manifest. Ticket 05 must verify dedicated header replacement
on every ready ingress instance before app trust is synchronized. Ticket 06
must confirm actual OCI listeners, LB and immediate-peer CIDRs, preserve
Terraform/Argo ownership and public Service identity, review a fresh full
plan, and perform public-source and shared-route acceptance during the agreed
maintenance window. The accepted trust model includes every caller in the
configured internal networks.
