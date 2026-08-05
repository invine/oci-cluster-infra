# 21 — Upgrade Longhorn to 1.12.0

**What to build:** Move the production Longhorn Shared Platform Service through every approved hop to `1.12.0`, validating storage fully after each isolated change.

**Blocked by:** 20 — Pass the starting gate and migrate the pool state address

**Status:** ready-for-human

- [ ] Each hop uses a separately reviewed full Terraform plan and receives explicit human authorization before apply.
- [ ] The exact sequence `1.7.2 → 1.8.2 → 1.9.2 → 1.10.2 → 1.11.3 → 1.12.0` is followed without combining or substituting releases.
- [ ] Matching official pre-upgrade and CRD procedures complete for every hop.
- [ ] After each hop, managers, CSI components, supporting workloads, nodes, disks, volumes, engines, and replicas are healthy.
- [ ] Every volume returns to three healthy replicas with no rebuild or storage operation pending before the next hop.
- [ ] No V2-engine enablement, unrelated storage migration, Explicit Secret mutation, or other plan change occurs.
- [ ] A failed check pauses progression for supported forward repair; no generic downgrade is assumed.
