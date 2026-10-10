# 04: Publish a verified echo release

**What to build:** A release operator can deploy the qualified client-identity
behavior using an available, immutable ARM64 image and a reviewed chart revision
whose Application parameters identify the intended image and trust contract.
The result is a deployable release package; it does not activate the feature in
the cluster.

**Blocked by:** 02 — Qualify the complete client-identity path.

**Status:** ready-for-agent

- [ ] Use the source qualified by ticket 02 and identify the exact release
  commit. Review the concrete publication and merge actions and obtain execution
  authorization before carrying them out; approval of this ticket breakdown is
  not release authorization.
- [ ] Publish the reviewed echo image through the existing release workflow.
  The prepared tag is `v0.0.4`; if occupied by another release, select and review
  a new immutable tag rather than overwriting it.
- [ ] Verify the published registry artifact exists, includes Linux ARM64 and
  matches the reviewed release. Record its digest, tag and source revision.
- [ ] Finalize the chart and active child Application against that available
  image. Render the exact release parameters and verify opt-in app trust,
  explicit trusted networks and the F5 dedicated-header overwrite contract.
- [ ] Publish or merge the reviewed chart/Application change only after the
  image has been verified. Record the exact chart commit for both subsequent
  Argo sync stages; do not leave the deployment dependent on a moving revision.
- [ ] Preserve manual synchronization of the echo child Application. Confirm
  that Bootstrap Seed reconciliation alone does not deploy the new echo image
  or enable shared LB PROXY protocol.
- [ ] Hand off the release digest, chart revision and relevant qualification
  evidence. Any implementation changes after ticket 02 are requalified before
  declaring the release ready.
- [ ] Do not synchronize the echo workload, apply platform changes or perform
  DNS/Service mutations as part of this ticket.
