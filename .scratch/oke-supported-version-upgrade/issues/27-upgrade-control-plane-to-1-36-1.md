# 27 — Upgrade the control plane to v1.36.1

**What to build:** Revalidate exact target availability and retained-worker skew, obtain Approval Gate 4, and move only the production OKE control plane from `v1.35.2` to `v1.36.1`.

**Blocked by:** 26 — Upgrade the control plane to v1.35.2

**Status:** ready-for-human

- [ ] The `v1.35.2` cluster is re-queried and OCI offers exact `v1.36.1` while supporting temporary `v1.34.2` workers.
- [ ] If either condition fails, the healthy cluster remains at `v1.35.2` and target selection is reopened without substituting another patch.
- [ ] The full plan changes only the control-plane version and retains the protected `v1.34.2` worker entry.
- [ ] Approval Gate 4 binds explicit human authorization to the exact plan and current evidence.
- [ ] The OCI work request completes and the cluster returns to `ACTIVE` on exactly `v1.36.1`.
- [ ] Complete post-hop system, platform, storage, Argo, ingress, Application Workload, and backup-storage checks pass.
- [ ] A failure pauses for forward recovery; the control plane is never downgraded.
