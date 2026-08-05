# 23 — Upgrade cert-manager to 1.21.1

**What to build:** Move production cert-manager through every approved minor to `v1.21.1` while preserving certificate issuance and all existing TLS endpoints.

**Blocked by:** 22 — Upgrade Velero to 1.18.1

**Status:** ready-for-human

- [ ] Helm ownership of the installed CRDs is confirmed before the first live hop.
- [ ] Each minor and matching CRD change has a separately reviewed full plan and explicit human authorization.
- [ ] The exact sequence through `v1.17.4`, `v1.18.6`, `v1.19.6`, `v1.20.3`, and `v1.21.1` is followed without combining or substitution.
- [ ] After every hop, controller, cainjector, webhook, and startup API check are ready.
- [ ] The ClusterIssuer and every Certificate remain Ready, and all declared HTTP/TLS endpoints succeed.
- [ ] No Explicit Secret rotation or unrelated plan change occurs.
- [ ] A failed CRD, webhook, certificate, endpoint, or plan gate pauses progression.
