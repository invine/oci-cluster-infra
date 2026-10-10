# 03: Qualify shared-ingress cutover and recovery

**What to build:** An operator can assess the real shared ingress, compare it
with the proposed client-identity change, and carry out a bounded maintenance
cutover or recovery using verified topology, health checks and endpoint
expectations. This is a read-only readiness package and can proceed alongside
local implementation qualification.

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] Inspect actual OCI listeners, backend sets, backend health and LB source
  subnet(s). Verify TCP forwarding to NGINX and document any intermediary before
  OCI that changes which source address reaches the infrastructure. Resolve
  mismatches with the agreed public-source interpretation before handoff.
- [x] Confirm the qualified F5 chart/controller pair against Live State. Do not
  combine client-identity activation with a controller upgrade.
- [x] Verify both LB-to-NGINX and NGINX-to-echo source networks. Record the exact
  proposed trusted CIDRs and their evidence, including the accepted trust of
  other internal callers. Do not assume the prepared example CIDRs are correct.
- [x] Capture the Service UID, ClusterIP, external IP, ports/NodePorts,
  selectors, ready EndpointSlices, Helm values and generated NGINX configuration
  needed to compare normal activation with its baseline.
- [x] Record expected HTTP, TLS, authentication and websocket behavior for all
  current shared-ingress endpoints, including Argo CD, echo, Vaultwarden, relay
  portal/WSS and any additional live routes. Include relevant ACME routes.
- [x] Verify OCI backend checks and the controller's actual health probes can
  remain usable after application listeners require PROXY protocol. Record
  whether dedicated readiness/liveness probes exist, and preserve the existing
  Local traffic policy. The sole owner accepts the observed health design,
  including the absence of a live liveness probe.
- [x] Verify a direct Kubernetes/OCI administrative path that remains usable
  if the shared public ingress and Argo UI are unavailable.
- [x] Prepare a full read-only platform preview for the proposed enablement.
  Record its configuration inputs and checksum. The expected normal resource
  action is one in-place ingress Helm update, with no additions, deletions,
  Explicit Secret changes, unrelated changes or DNS action. Treat the preview
  as preliminary if implementation qualification changes its inputs.
- [x] Document the maintenance sequence, observable success/failure conditions
  and responsible operator. Account for non-atomic OCI reconciliation and NGINX
  reloads without promising a measured outage duration that has not been tested.
- [x] Make recovery actionable for an echo-only failure and a shared-ingress
  failure while retaining agreement between LB and NGINX protocol settings.
  Explicitly exclude disabling the feature flag or blindly restoring old Helm
  values as routine rollback on the existing OCI LB.
- [x] Describe the separate review needed if Service/LB replacement becomes
  necessary: affected resources, recreation/reconciliation sequence, chosen
  replacement protocol, possible new public IP and explicit DNS update and
  verification. Do not substitute deletion of the entire ingress release.
- [x] Preserve the evidence as Local Sensitive Artifacts and hand off a
  reviewable readiness package. No image publication, Argo sync, Terraform apply,
  LB mutation, DNS update or destructive recovery action is performed here.

## Comments

2026-10-10: Read-only live qualification is recorded as Local Sensitive
Artifacts outside Git, in restricted `/private/tmp/echo-id-03-evidence/`.
The full readiness note is `readiness-2026-10-10.md`, SHA-256
`86b813934a603bb23d9054c42c8c4b96d787c057f459240372373c43c980ffe5`.
The full temporary-override Terraform preview is `platform.tfplan`, SHA-256
`b7576d04ef459e4de5ec4066c6a5e14899e1bfaea2aef959873829bff5ea7e20`.
The preliminary preview is 0 add / 1 in-place Helm update / 0 destroy.
The sole owner/maintainer is the responsible platform operator. They accept a
maintenance interruption at any time because no crucial workloads are served,
and accept the observed controller health design without adding a liveness
probe to this cutover. Record actual start/duration when execution is approved;
the current plan is preliminary until approved settings are persisted and a
fresh full plan is reviewed. The ticket remains claimed because authenticated
Argo CD, Vaultwarden, and relay portal behavior and an application-level relay
WebSocket exchange have not been substantiated. No production mutation was
performed. Preserve the private artifacts before clearing temporary storage.

2026-10-10: The sole owner reports successful authenticated safe reads for
Argo CD and Vaultwarden, relay portal login, and an application-level relay
WebSocket exchange. These outcomes are owner-reported rather than independently
observed by this qualification. The full private readiness note was updated;
its current SHA-256 is
`10315384f5b75f8bd6b688b3b8a8f3f668c7d6106d960e8159e3368306d07990`.
The earlier note checksum above is superseded. All read-only qualification
items are now recorded. Fresh planning from persisted inputs, staged sync,
maintenance cutover, and production acceptance remain ticket 06 execution
gates.

## Answer

The shared-ingress cutover and recovery are qualified as a read-only readiness
package. Actual infrastructure, controller, trust boundaries, routes, health
design, administrative access, and recovery path were assessed; the sole owner
accepted the maintenance and health approach and reported the four remaining
authenticated/application-level baseline checks as passed. The preliminary
full platform preview has only one in-place ingress Helm update. The complete
live evidence and plan remain restricted outside Git at
`/private/tmp/echo-id-03-evidence/`; the current readiness note checksum is
`10315384f5b75f8bd6b688b3b8a8f3f668c7d6106d960e8159e3368306d07990`.
This resolution authorizes no production mutation. Ticket 06 must repeat the
endpoint checks and approve a fresh plan after deployment inputs are persisted.
