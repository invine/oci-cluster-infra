# 03: Qualify shared-ingress cutover and recovery

**What to build:** An operator can assess the real shared ingress, compare it
with the proposed client-identity change, and carry out a bounded maintenance
cutover or recovery using verified topology, health checks and endpoint
expectations. This is a read-only readiness package and can proceed alongside
local implementation qualification.

**Blocked by:** None (can start immediately).

**Status:** claimed

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
- [ ] Record expected HTTP, TLS, authentication and websocket behavior for all
  current shared-ingress endpoints, including Argo CD, echo, Vaultwarden, relay
  portal/WSS and any additional live routes. Include relevant ACME routes.
- [ ] Verify OCI backend checks and dedicated controller readiness/liveness
  endpoints can remain usable after application listeners require PROXY
  protocol. Preserve the existing Local traffic policy.
- [x] Verify a direct Kubernetes/OCI administrative path that remains usable
  if the shared public ingress and Argo UI are unavailable.
- [x] Prepare a full read-only platform preview for the proposed enablement.
  Record its configuration inputs and checksum. The expected normal resource
  action is one in-place ingress Helm update, with no additions, deletions,
  Explicit Secret changes, unrelated changes or DNS action. Treat the preview
  as preliminary if implementation qualification changes its inputs.
- [ ] Document the maintenance sequence, observable success/failure conditions
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
`55f76bd0ef04bf1ffaa851078d16d78b0ad17730c8138342607afbd8493b2839`.
The full temporary-override Terraform preview is `platform.tfplan`, SHA-256
`b7576d04ef459e4de5ec4066c6a5e14899e1bfaea2aef959873829bff5ea7e20`.
The preliminary preview is 0 add / 1 in-place Helm update / 0 destroy.
The ticket remains open: authenticated/shared endpoint checks, the live
controller health design, named operator/window, and a final plan from
persisted inputs need review. No production mutation was performed. Preserve
the private artifacts before clearing temporary storage.
