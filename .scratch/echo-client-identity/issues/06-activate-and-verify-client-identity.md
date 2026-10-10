# 06: Activate and verify public client identity

**What to build:** An external caller's requests produce accurate public-source
identity in echo's existing logs through the shared OCI/F5 ingress, with source
port when available, while all shared Application Workload endpoints pass their
recorded baseline after the maintenance cutover.

**Blocked by:** 05 — Stage echo's trusted-header handling safely.

**Status:** resolved

- [x] Reconfirm ticket 05's staged release and the readiness/recovery package
  inherited from ticket 03. Refresh any changed configuration, Live State,
  endpoint baseline, trust ranges or release evidence before planning activation.
- [x] Persist the reviewed qualified controller version, PROXY enablement and
  explicit LB trust settings in the existing protected deployment configuration,
  preserving unrelated values. Future full plans must retain the enabled state.
- [x] Generate a fresh full saved Terraform plan, without targeting resources.
  Require only the intended in-place ingress Helm update and dependent reads.
  Inspect rendered differences and reject unrelated changes, Explicit Secret
  changes, Service replacement, normal-path public-IP change or DNS action.
- [x] Present the exact plan checksum, image digest, chart/source revisions,
  baseline, maintenance window and recovery procedure for approval. Obtain
  explicit execution authorization before applying the saved plan; ticket
  readiness does not authorize production activation.
- [x] Apply during the approved maintenance window through Terraform ownership.
  Verify every OCI listener and ready NGINX instance agrees on PROXY v2 before
  considering traffic restored. Check LB backends, reload errors, Service
  identity/public IP, ready endpoints and dedicated health checks.
- [x] From an external client with an independently known public source, send
  labelled GET, POST, ping, missing-message and invalid-JSON requests. Verify
  the established responses and log levels, correct `clientIp`, and retained
  ingress-connection `remoteAddr` for every existing request-log path.
- [x] Verify public caller-supplied identity and forwarding headers, including
  duplicates, cannot override the authoritative client fields. Neither the LB
  private address nor the ingress pod IP may be reported as the public client.
- [x] When `clientPort` is present, verify it is valid source-port metadata rather
  than a destination port. Corroborate it at a controlled public-client/edge
  boundary where feasible and record any verification limit. Port absence must
  not prevent acceptance of an otherwise correct client IP; never infer a port
  that the transport metadata did not provide.
- [x] Pass the full recorded HTTP, TLS, authentication, websocket and relevant
  ACME baseline for every shared-ingress endpoint. Healthy pods or a successful
  Helm operation alone do not satisfy acceptance.
- [x] If acceptance fails, follow the reviewed recovery route while keeping
  LB and NGINX protocols aligned. An echo-only rollback must not disable the
  shared PROXY configuration. Any necessary Service/LB replacement and DNS
  update requires its own concrete reviewed authorization and post-recovery checks.
- [x] Record all results and the resulting Live State, keeping sensitive
  evidence private. Declare this ticket complete only when public identity and
  all shared-endpoint gates pass. If recovered to a functioning state without
  client identity, record the recovery and leave the feature incomplete.
- [x] Hand the acceptance evidence to the owner of the existing rollout handoff.
  Do not modify or close the parent specification or overall handoff ticket as
  part of this child ticket.

## Comments

2026-10-10: The owner authorized completion of the shared PROXY cutover and
reported all four authenticated post-stage checks passed. The protected local
Terraform configuration now persists chart 2.6.4, snippets, PROXY enablement
and OCI LB CIDR `10.0.8.0/24`. A fresh full saved plan, SHA-256
`b8cdd462d9ca7854360a25fdf9ebfd686f0bbea52756979ff506777a61e59832`,
showed only one in-place ingress Helm update and a dependent Service read.
Terraform applied that exact plan: 0 added, 1 changed, 0 destroyed. Both OCI
listeners now send PROXY v2; all four ready F5 pods parse it; two backend sets
are healthy; ingress Service UID and public IP are unchanged. Public labelled
GET, POST, ping and warning requests log the independently observed public IP,
retain ingress `remoteAddr`, and resist forged duplicate identity headers. A
controlled client source port `55040` matched the logged `clientPort`. Public
HTTP, TLS and WebSocket Upgrade baseline passes; no ACME challenge is active.
The authenticated post-cutover shared-route checks are pending the owner's
report. Restricted evidence is in
`/private/tmp/echo-id-deploy-evidence/cutover-2026-10-10.md`.

2026-10-10: The owner reported all four authenticated post-cutover checks
passed: Argo CD read, Vaultwarden read, relay portal login and an
application-level relay WebSocket exchange. No ACME challenge was active.
The recovery condition did not arise, so no recovery mutation was performed.
The private acceptance record above is the handoff to the sole owner.

## Answer

Public client identity is live through Terraform-managed OCI/F5 PROXY v2 and
Argo-managed echo `v0.0.4`. The public source IP, source port, request-log
paths, spoof resistance and all shared-route baselines passed. The ingress
Service UID and public IP were preserved, and a post-apply full Terraform plan
reported no changes. Detailed evidence is in
`/private/tmp/echo-id-deploy-evidence/cutover-2026-10-10.md` and
`../validation.md`.
