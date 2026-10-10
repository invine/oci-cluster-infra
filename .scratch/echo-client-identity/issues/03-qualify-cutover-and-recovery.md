# 03: Qualify shared-ingress cutover and recovery

**What to build:** An operator can assess the real shared ingress, compare it
with the proposed client-identity change, and carry out a bounded maintenance
cutover or recovery using verified topology, health checks and endpoint
expectations. This is a read-only readiness package and can proceed alongside
local implementation qualification.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] Inspect actual OCI listeners, backend sets, backend health and LB source
  subnet(s). Verify TCP forwarding to NGINX and document any intermediary before
  OCI that changes which source address reaches the infrastructure. Resolve
  mismatches with the agreed public-source interpretation before handoff.
- [ ] Confirm the qualified F5 chart/controller pair against Live State. Do not
  combine client-identity activation with a controller upgrade.
- [ ] Verify both LB-to-NGINX and NGINX-to-echo source networks. Record the exact
  proposed trusted CIDRs and their evidence, including the accepted trust of
  other internal callers. Do not assume the prepared example CIDRs are correct.
- [ ] Capture the Service UID, ClusterIP, external IP, ports/NodePorts,
  selectors, ready EndpointSlices, Helm values and generated NGINX configuration
  needed to compare normal activation with its baseline.
- [ ] Record expected HTTP, TLS, authentication and websocket behavior for all
  current shared-ingress endpoints, including Argo CD, echo, Vaultwarden, relay
  portal/WSS and any additional live routes. Include relevant ACME routes.
- [ ] Verify OCI backend checks and dedicated controller readiness/liveness
  endpoints can remain usable after application listeners require PROXY
  protocol. Preserve the existing Local traffic policy.
- [ ] Verify a direct Kubernetes/OCI administrative path that remains usable
  if the shared public ingress and Argo UI are unavailable.
- [ ] Prepare a full read-only platform preview for the proposed enablement.
  Record its configuration inputs and checksum. The expected normal resource
  action is one in-place ingress Helm update, with no additions, deletions,
  Explicit Secret changes, unrelated changes or DNS action. Treat the preview
  as preliminary if implementation qualification changes its inputs.
- [ ] Document the maintenance sequence, observable success/failure conditions
  and responsible operator. Account for non-atomic OCI reconciliation and NGINX
  reloads without promising a measured outage duration that has not been tested.
- [ ] Make recovery actionable for an echo-only failure and a shared-ingress
  failure while retaining agreement between LB and NGINX protocol settings.
  Explicitly exclude disabling the feature flag or blindly restoring old Helm
  values as routine rollback on the existing OCI LB.
- [ ] Describe the separate review needed if Service/LB replacement becomes
  necessary: affected resources, recreation/reconciliation sequence, chosen
  replacement protocol, possible new public IP and explicit DNS update and
  verification. Do not substitute deletion of the entire ingress release.
- [ ] Preserve the evidence as Local Sensitive Artifacts and hand off a
  reviewable readiness package. No image publication, Argo sync, Terraform apply,
  LB mutation, DNS update or destructive recovery action is performed here.
