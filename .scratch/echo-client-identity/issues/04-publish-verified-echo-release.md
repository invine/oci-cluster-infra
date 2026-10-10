# 04: Publish a verified echo release

**What to build:** A release operator can deploy the qualified client-identity
behavior using an available, immutable ARM64 image and a reviewed chart revision
whose Application parameters identify the intended image and trust contract.
The result is a deployable release package; it does not activate the feature in
the cluster.

**Blocked by:** 02 — Qualify the complete client-identity path.

**Status:** resolved

- [x] Use the source qualified by ticket 02 and identify the exact release
  commit. Review the concrete publication and merge actions and obtain execution
  authorization before carrying them out; approval of this ticket breakdown is
  not release authorization.
- [x] Publish the reviewed echo image through the existing release workflow.
  The prepared tag is `v0.0.4`; if occupied by another release, select and review
  a new immutable tag rather than overwriting it.
- [x] Verify the published registry artifact exists, includes Linux ARM64 and
  matches the reviewed release. Record its digest, tag and source revision.
- [x] Finalize the chart and active child Application against that available
  image. Render the exact release parameters and verify opt-in app trust,
  explicit trusted networks and the F5 dedicated-header overwrite contract.
- [x] Publish or merge the reviewed chart/Application change only after the
  image has been verified. Record the exact chart commit for both subsequent
  Argo sync stages; do not leave the deployment dependent on a moving revision.
- [x] Preserve manual synchronization of the echo child Application. Confirm
  that Bootstrap Seed reconciliation alone does not deploy the new echo image
  or enable shared LB PROXY protocol.
- [x] Hand off the release digest, chart revision and relevant qualification
  evidence. Any implementation changes after ticket 02 are requalified before
  declaring the release ready.
- [x] Do not synchronize the echo workload, apply platform changes or perform
  DNS/Service mutations as part of this ticket.

## Preparation, 2026-10-10

The reviewed local candidate and initial publication gate are documented in
[the release package](../release-package.md). Publication was subsequently
authorized and verified as recorded below.

## Answer

The qualified echo source is
`81bc06dfb5081b748f33adc1f5b01b939e06b60d`. Remote `main` and the peeled
annotated tag `v0.0.4` both resolve to it. The
[tag workflow run](https://github.com/invine/echo/actions/runs/38055451405)
completed successfully at that SHA. The published
`ghcr.io/invine/echo:v0.0.4` manifest resolves to
`sha256:5dfc2d5be2f1f23748c9d3ed4bf4403a61e835481bf343a2fa971e8f16a150ca`
and reports `linux/arm64`.

The chart repository's remote `main` is
`d256b1860ea751f6a3e28d2662007cb19f96af50`. A fresh render from that
exact commit matched the prepared release contract and manifest checksum.
Use **this exact chart SHA** for both later Argo sync stages. The live echo
child still has no automated sync policy and remains on `v0.0.3` at its older
synced revision, so this release has not activated client identity. Shared LB
PROXY activation and production acceptance belong to later tickets. See the
[release package](../release-package.md) for the full handoff and checks.
