# 16 — Prepare the cert-manager upgrade path

**What to build:** Prepare cert-manager for serial upgrades through `v1.21.1` with Helm-owned CRDs and explicit certificate and endpoint checks at every hop.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] The prepared sequence is exactly `v1.16.1 → v1.17.4 → v1.18.6 → v1.19.6 → v1.20.3 → v1.21.1`.
- [ ] The legacy CRD installation setting is replaced by the current Helm-managed CRD setting.
- [ ] The procedure requires confirmation of Helm ownership before the first live hop and upgrades matching CRDs with every chart hop.
- [ ] Every hop defines exit checks for the controller, cainjector, webhook, startup API check, ClusterIssuer, Certificates, and existing HTTP/TLS endpoints.
- [ ] Terraform formatting and non-mutating validation pass; no CRD, certificate, or release mutation is performed.
