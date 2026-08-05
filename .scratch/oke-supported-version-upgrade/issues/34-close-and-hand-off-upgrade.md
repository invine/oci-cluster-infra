# 34 — Close and hand off the upgrade

**What to build:** Produce the final auditable record of the completed production upgrade and hand its residual risks and operating state to the cluster owner.

**Blocked by:** 33 — Retire the v1.34.2 worker pool

**Status:** ready-for-human

- [ ] Final control-plane version, worker versions, approved image OCIDs, and Shared Platform Service pins are recorded.
- [ ] Reviewed plans, applies, OCI work requests, state migration, node migrations, functional results, backups, and all six approvals are linked or recorded without exposing sensitive values.
- [ ] Post-deletion verification is complete and the runbook has no unresolved failed gate.
- [ ] Residual risks explicitly state that restoreability was not rehearsed, Application Workloads remain singleton/non-HA where identified, and worker rollback is unavailable.
- [ ] Local Sensitive Artifacts remain untracked and retain restrictive permissions.
- [ ] The upgrade is declared complete only when the evidence package has a named owner; otherwise it remains paused with a recorded next action.
