# 33 — Retire the v1.34.2 worker pool

**What to build:** Cross the final rollback boundary through two reviewed Terraform changes, delete only the old pool, and prove the remaining production cluster is healthy.

**Blocked by:** 32 — Pass Migration Acceptance

**Status:** ready-for-human

- [ ] Approval Gate 6 evidence is still current before any lifecycle protection is weakened.
- [ ] The first reviewed change removes destruction protection while retaining both map entries, and its full plan shows no infrastructure changes.
- [ ] The second reviewed change removes only the `v1.34.2` entry, and its fresh full plan shows destruction of only the old pool.
- [ ] Explicit human authorization is obtained for the exact destruction plan immediately before apply.
- [ ] OCI reports deletion complete and the old Kubernetes nodes disappear.
- [ ] Node, pod, DaemonSet, Longhorn, Argo, ingress, Application Workload, repository, Backup Storage Location, and functional checks pass after deletion.
- [ ] The evidence states that worker rollback is no longer available and subsequent failures use forward repair and the accepted backup posture.
