# 16 — Prepare the cert-manager upgrade path

**What to build:** Prepare cert-manager for serial upgrades through `v1.21.1` with Helm-owned CRDs and explicit certificate and endpoint checks at every hop.

**Blocked by:** None — can start immediately

**Status:** resolved

- [x] The prepared sequence is exactly `v1.16.1 → v1.17.4 → v1.18.6 → v1.19.6 → v1.20.3 → v1.21.1`.
- [x] The legacy CRD installation setting is replaced by the current Helm-managed CRD setting.
- [x] The procedure requires confirmation of Helm ownership before the first live hop and upgrades matching CRDs with every chart hop.
- [x] Every hop defines exit checks for the controller, cainjector, webhook, startup API check, ClusterIssuer, Certificates, and existing HTTP/TLS endpoints.
- [x] Terraform formatting and non-mutating validation pass; no CRD, certificate, or release mutation is performed.

## Comments

- 2026-08-06 implementation completed with a frozen `cert_manager_version`
  allowlist and the current `crds.enabled` Helm value, preserving Helm as the
  sole lifecycle owner for matching cert-manager CRDs.
- Added `docs/runbooks/cert-manager-upgrade.md` with the exact five-hop path,
  one-time Helm ownership gate, per-hop CRD lifecycle and release-note review,
  full controller/cainjector/webhook/startup API/issuer/certificate/endpoint
  checks, plan approval boundaries, and forward-repair stop behavior.
- `terraform fmt -check -recursive`, `git diff --cached --check`,
  `terraform -chdir=infra validate`, and `terraform -chdir=platform validate`
  passed. No Terraform plan or apply, Helm action, Kubernetes query or
  mutation, CRD change, certificate action, or release mutation was performed.
- The required two-axis review reported zero remaining Standards findings and
  zero Spec findings after correcting the ACME account key's domain term to
  Generated Resource.
