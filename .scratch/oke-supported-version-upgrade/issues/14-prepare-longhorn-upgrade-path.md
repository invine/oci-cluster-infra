# 14 — Prepare the Longhorn upgrade path

**What to build:** Prepare a reviewable, operator-usable Longhorn path from `1.7.2` to `1.12.0` that keeps storage compatibility checks and CRD handling attached to every serial hop without changing Live State.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] The prepared sequence is exactly `1.7.2 → 1.8.2 → 1.9.2 → 1.10.2 → 1.11.3 → 1.12.0` with no automatic version substitution.
- [ ] Every hop identifies its matching chart/application release, official pre-upgrade checks, and CRD lifecycle.
- [ ] Every hop defines observable exit checks for managers, CSI components, supporting workloads, nodes, disks, volumes, engines, and replicas.
- [ ] Progress requires three healthy replicas for every volume with no rebuild or other storage operation pending.
- [ ] The prepared configuration keeps the V2 engine disabled and introduces no unrelated storage migration.
- [ ] Terraform formatting and non-mutating validation pass; no platform plan or apply is performed.
