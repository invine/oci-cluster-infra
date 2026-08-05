# 25 — Upgrade Argo CD to 3.5.0 and approve platform completion

**What to build:** Move production Argo CD through every approved release to `3.5.0`, prove the complete platform remains healthy, and record Approval Gate 2 before control-plane planning begins.

**Blocked by:** 24 — Upgrade F5 NGINX to 5.5.4

**Status:** ready-for-human

- [ ] Each Argo CD release and matching CRD hop has a separately reviewed full plan and explicit human authorization.
- [ ] Every approved chart/application pair is applied in order without combining or substitution, with applicable upgrade notes satisfied.
- [ ] The Bootstrap Seed, Repository Registration, Explicit Secrets, and manual child-Application sync policy remain preserved.
- [ ] After every hop, all Argo CD components are ready, API/UI access works, repositories are connected, and every Application is Healthy and Synced.
- [ ] After the final hop, complete platform, storage, ingress, Application Workload, functional, repository, and fresh-backup checks pass.
- [ ] Approval Gate 2 records the exact evidence and authorizes control-plane planning only.
- [ ] Drift or a failed check invalidates the approval and pauses progression.
