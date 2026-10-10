# 06: Activate and verify public client identity

**What to build:** An external caller's requests produce accurate public-source
identity in echo's existing logs through the shared OCI/F5 ingress, with source
port when available, while all shared Application Workload endpoints pass their
recorded baseline after the maintenance cutover.

**Blocked by:** 05 — Stage echo's trusted-header handling safely.

**Status:** ready-for-agent

- [ ] Reconfirm ticket 05's staged release and the readiness/recovery package
  inherited from ticket 03. Refresh any changed configuration, Live State,
  endpoint baseline, trust ranges or release evidence before planning activation.
- [ ] Persist the reviewed qualified controller version, PROXY enablement and
  explicit LB trust settings in the existing protected deployment configuration,
  preserving unrelated values. Future full plans must retain the enabled state.
- [ ] Generate a fresh full saved Terraform plan, without targeting resources.
  Require only the intended in-place ingress Helm update and dependent reads.
  Inspect rendered differences and reject unrelated changes, Explicit Secret
  changes, Service replacement, normal-path public-IP change or DNS action.
- [ ] Present the exact plan checksum, image digest, chart/source revisions,
  baseline, maintenance window and recovery procedure for approval. Obtain
  explicit execution authorization before applying the saved plan; ticket
  readiness does not authorize production activation.
- [ ] Apply during the approved maintenance window through Terraform ownership.
  Verify every OCI listener and ready NGINX instance agrees on PROXY v2 before
  considering traffic restored. Check LB backends, reload errors, Service
  identity/public IP, ready endpoints and dedicated health checks.
- [ ] From an external client with an independently known public source, send
  labelled GET, POST, ping, missing-message and invalid-JSON requests. Verify
  the established responses and log levels, correct `clientIp`, and retained
  ingress-connection `remoteAddr` for every existing request-log path.
- [ ] Verify public caller-supplied identity and forwarding headers, including
  duplicates, cannot override the authoritative client fields. Neither the LB
  private address nor the ingress pod IP may be reported as the public client.
- [ ] When `clientPort` is present, verify it is valid source-port metadata rather
  than a destination port. Corroborate it at a controlled public-client/edge
  boundary where feasible and record any verification limit. Port absence must
  not prevent acceptance of an otherwise correct client IP; never infer a port
  that the transport metadata did not provide.
- [ ] Pass the full recorded HTTP, TLS, authentication, websocket and relevant
  ACME baseline for every shared-ingress endpoint. Healthy pods or a successful
  Helm operation alone do not satisfy acceptance.
- [ ] If acceptance fails, follow the reviewed recovery route while keeping
  LB and NGINX protocols aligned. An echo-only rollback must not disable the
  shared PROXY configuration. Any necessary Service/LB replacement and DNS
  update requires its own concrete reviewed authorization and post-recovery checks.
- [ ] Record all results and the resulting Live State, keeping sensitive
  evidence private. Declare this ticket complete only when public identity and
  all shared-endpoint gates pass. If recovered to a functioning state without
  client identity, record the recovery and leave the feature incomplete.
- [ ] Hand the acceptance evidence to the owner of the existing rollout handoff.
  Do not modify or close the parent specification or overall handoff ticket as
  part of this child ticket.
