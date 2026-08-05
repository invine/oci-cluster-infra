# 18 — Prepare the Argo CD upgrade path

**What to build:** Prepare the complete Argo CD chart/application/CRD sequence to `3.5.0` while preserving Terraform's Bootstrap Seed and Repository Registration and Argo CD's Application graph.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] The prepared chart/application sequence is exactly `7.6.12/2.12.6 → 7.7.23/2.13.4 → 7.9.1/2.14.11 → 8.2.7/3.0.12 → 9.0.6/3.1.9 → 9.3.7/3.2.6 → 9.5.11/3.3.9 → 10.2.2/3.4.6 → 10.2.3/3.5.0`.
- [ ] Each hop upgrades the complete release and its matching CRDs rather than only container images.
- [ ] Intervening official upgrade-note requirements are captured as preconditions for their corresponding hops.
- [ ] The Bootstrap Seed, bootstrap Repository Registration, Explicit Secrets, and manual child-Application sync policy remain unchanged.
- [ ] Every hop defines exit checks for all Argo CD components, API/UI access, repository connections, and every Application's Healthy/Synced state.
- [ ] Terraform formatting and non-mutating validation pass; no Helm, CRD, Application, repository, or Secret mutation is performed.
