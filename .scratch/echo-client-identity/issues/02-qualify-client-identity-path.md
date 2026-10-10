# 02: Qualify the complete client-identity path

**What to build:** A verified path from LB transport metadata through F5 NGINX
to echo's existing request logs, giving operators an accurate client IP and an
optional source port without losing the immediate peer or changing responses.
Qualify the implementation already prepared across the three repositories;
reuse it and its matching validation evidence, and fix only demonstrated gaps.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] Review the prepared implementation against the confirmed echo client
  identity specification and identify the exact source revisions or working-tree
  snapshots being qualified. Preserve unrelated user changes.
- [ ] Exercise the existing request-to-log boundary through the matching F5
  NGINX image and built echo binary using real PROXY v2 metadata. Verify IPv4,
  IPv6 and existing v1 compatibility without introducing a new public test API.
- [ ] Existing GET, POST, ping, missing-message and invalid-JSON paths retain
  their response behavior and log levels. Their logs retain the connection's
  `remoteAddr` and add a validated `clientIp` plus optional numeric `clientPort`.
- [ ] The source port is accepted only in the range 1–65535 and is never inferred
  from a destination-port header. Invalid or unavailable port metadata omits
  only the port when the IP remains valid.
- [ ] Missing, malformed, duplicate, chained, scoped, unspecified or multicast
  IP metadata omits both client fields without rejecting the request. Verify
  IPv4-mapped normalization and trust checks as externally observable behavior.
- [ ] Forged public HTTP identity headers, including duplicates, cannot override
  PROXY metadata. Empty PROXY metadata removes dedicated headers rather than
  passing caller-supplied values through. Ordinary forwarding headers cannot
  become an alternate authoritative identity source.
- [ ] App trust defaults to disabled and accepts metadata only from configured
  immediate-peer CIDRs. Invalid or catch-all trust is rejected. Document that
  every caller within the configured internal networks is trusted.
- [ ] Render the active echo Application parameters and F5 before/after values.
  Verify the dedicated header overwrites, required trusted networks, opt-in
  behavior and native F5 configuration. Enabling app identity without its trust
  configuration must fail validation.
- [ ] The rendered platform change preserves Service identity, selectors,
  traffic policy and controller DaemonSet, adding only the intended Service
  PROXY annotation and native ConfigMap settings. Preserve Terraform and Argo CD
  ownership and exclusive Terraform ownership of OCI security lists.
- [ ] Record passing Go tests with the race detector, static checks, ARM64 build,
  Helm validation and the isolated proxy test for the qualified implementation.
  Reuse existing evidence when it matches unchanged inputs; rerun checks affected
  by any fixes. Keep sensitive evidence as Local Sensitive Artifacts.
- [ ] Hand off the qualified source snapshots and any remaining operational
  assumptions to the release and cutover tickets. Completion does not claim
  production acceptance or authorize publication or deployment.
