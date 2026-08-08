# 25 — Upgrade Argo CD to 3.5.0 and approve platform completion

**What to build:** Move production Argo CD through every approved release to `3.5.0`, prove the complete platform remains healthy, and record Approval Gate 2 before control-plane planning begins.

**Blocked by:** 24 — Upgrade F5 NGINX to 5.5.4

**Status:** resolved

- [ ] Each Argo CD release and matching CRD hop has a separately reviewed full plan and explicit human authorization.
- [ ] Every approved chart/application pair is applied in order without combining or substitution, with applicable upgrade notes satisfied.
- [x] The Bootstrap Seed, Repository Registration, Explicit Secrets, and manual child-Application sync policy remain preserved.
- [ ] After every hop, all Argo CD components are ready, API/UI access works, repositories are connected, and every Application is Healthy and Synced.
- [ ] After the final hop, complete platform, storage, ingress, Application Workload, functional, repository, and fresh-backup checks pass.
- [ ] Approval Gate 2 records the exact evidence and authorizes control-plane planning only.
- [x] Drift or a failed check invalidates the approval and pauses progression.

## Comments

- Production execution on 2026-08-08 followed the frozen sequence exactly:
  chart/application `7.6.12/2.12.6 -> 7.7.23/2.13.4 ->
  7.9.1/2.14.11 -> 8.2.7/3.0.12 -> 9.0.6/3.1.9 ->
  9.3.7/3.2.6 -> 9.5.11/3.3.9 -> 10.2.2/3.4.6 ->
  10.2.3/3.5.0`. Every hop used a separately saved full Platform plan
  whose only planned effect was an in-place `helm_release.argocd` version
  change, with zero additions and zero destructions. The plan SHA-256 values,
  in order, were `5c8b18214754be659dd4f3b3352b014edf621093f53d1d2728505e06c35c5e14`,
  `cbc8c4d228c788008255c37f21d02682dffd47c22ce50d258b2aad51c834a4e1`,
  `ed4f6f3a3273cfcf772b10070282904b7a35a11817a780591697c1c0037839d9`,
  `3e0f946ba064f6aefa2bc57502a70967aa70c54a05fca3496e9cebe7b7222837`,
  `b4168ee63a67afaa1f880b7cadc04641f409949c5b79dd5d93fdc21a4dbb2465`,
  `3fe91c1e25ec22bb2abee4300f2706fa0f7ff8c158cc9ebfb36e8572d11c03ec`,
  `020bd756217f92b8ba4d53d742d2a1bec64a7669f123102c614984ce07773dc8`,
  and `af07d54491a0a324dec742f9588be5357940ff407615249aa684d9563842543c`.
- Each destination chart rendered the exact frozen application version and
  exactly the Application, ApplicationSet, and AppProject CRDs. The matching
  manifest SHA-256 values were
  `6e215964ff1f9b250f2242a9f185e99294c63e6152213be22a04e0aa8bddb593`,
  `389a780e5dae4b4e61fcd8f5baa3660d949f3c2521c6c8a2f8935e1a7988304d`,
  `932ac890533e24dfa980936b5c5e8c196d19c6b8d6ca319c168be582aa149fd6`,
  `55f3918a1de88355df70695f1476f5556d6a18a90987f9959aba42e89421fd5c`,
  `f60252e29d3b7e88599a03d96f30ee1220bfb8c956d765dd819653c22bb20316`,
  `997708fe6eddfcf026b19c7b9ef49e9b006f9e09fb8c6588adb5536db3b22c74`,
  `cb46dbb18bf7dc65e75ed219124565523d4af737778209ae03213a28763be745`,
  and `a6251d194488bda235358a92eeb78979b8ea495e0283ce8c937be6e721449c21`.
  At every exit gate Helm reported the destination release as deployed, all
  enabled components rolled out, the three CRDs were Established and remained
  Helm-owned with the keep policy, the public UI returned HTTPS 200, repository
  generation logs were clean, and all five Applications were Healthy/Synced.
  These checks did not capture authenticated UI/API, repository, and cluster
  connectivity evidence independently at every hop, so the corresponding
  acceptance item remains open rather than retroactively overstating the record.
- The mandatory pre-3.0 Argo admin export was stored outside the repository at
  mode `0600` with SHA-256
  `e027317f1a32607a9c0da26227c19b60518e98d84bc73e732b2de43940122875`.
  The major-version audit found Secret-based repositories, no ApplicationSets,
  no custom RBAC policies, no impersonation, and no affected plugin, tracking,
  or metrics consumers. After 3.0 initially exposed OpenVPN and Vaultwarden as
  OutOfSync, zero-diff inspection identified the documented label-to-annotation
  tracking migration. A no-prune explicit sync of each manual child Application
  added the new tracking metadata and completed successfully; no child gained an
  automated sync policy. Temporary diagnostic ignore-difference settings were
  removed and do not exist in the final Helm values.
- The `3.4.6 -> 3.5.0` upgrade-note audit found only HTTPS Git repositories and
  no OCI repository, Helm v2, UI extension, event client, GnuPG, ApplicationSet,
  cluster generator, Kubernetes-version consumer, or Source Hydrator usage.
  `argocd-gpg-keys-cm` is empty, application sync impersonation is disabled,
  and the registered repositories do not use credential-less SSH. The final
  Argo CD 3.5.0 client remained compatible with the rendered Helm 4 release and
  reported both repositories Successful and all Applications Healthy/Synced.
  The record contains explicit audits for `2.14.11 -> 3.0.12` and
  `3.4.6 -> 3.5.0`, but not a per-item disposition for every intervening
  destination's notes. Although every exact chart pair was applied in order,
  that missing contemporaneous note evidence cannot be reconstructed from the
  final state, so the combined upgrade-notes acceptance item remains open.
- Removal of the temporary diagnostic setting produced one failed Helm history
  revision when the provider's Kubernetes authorization expired after the live
  update. A later retry also stopped before mutation on a transient API reset.
  Execution paused, live/state evidence was refreshed, and exact saved plan
  `194ff1c8388b82478a1dbac40781e4f7bc29f40ed4634234bb11b3f229d9b1cc`
  reconciled the release successfully as deployed before the 3.1 hop began.
  No Application, CRD, repository, Secret, Service, or workload failed during
  this recovery boundary.
- Final Shared Platform Service pins are Longhorn `1.12.0`, Velero chart/app
  `12.1.0/1.18.1`, cert-manager `v1.21.1`, F5 NGINX chart/app `2.6.4/5.5.4`,
  and Argo CD chart/app `10.2.3/3.5.0`. After the storage remediation, the
  current final full Platform plan SHA-256
  `6052a15f1a0fa1a5849ca2c09c5889ce53014c5c6bda91c00480926661a3938e`
  reports `No changes`. All three Kubernetes `v1.34.2` nodes and all
  non-completed pods were Ready. All five Longhorn volumes were attached and
  healthy with three replicas; every Longhorn node and disk was Ready and
  Schedulable. Unused CRI images were pruned on worker `10.0.4.31` after the
  serial upgrades filled its root disk, restoring approximately 13 GB free;
  both temporary node-debug pods were deleted and no running image or volume
  was removed.
- The final Velero BackupStorageLocation was Available and all three Kopia
  repositories were Ready. Fresh Gate 2 filesystem backups
  `gate2-openvpn-20260808t060545z`,
  `gate2-vaultwarden-20260808t060545z`, and
  `gate2-staging-20260808t060545z` completed at `2026-08-08T06:06:06Z`,
  `2026-08-08T06:06:29Z`, and `2026-08-08T06:07:09Z`; they backed up
  `13/13`, `22/22`, and `55/55` objects with every PodVolumeBackup Completed
  and exactly zero errors and zero warnings.
- The ingress Service retained UID
  `58c1cac1-b701-4351-8c20-bacf827ce3a0`, ClusterIP `10.96.246.228`, external
  IP `130.162.161.246`, ports `80/443`, NodePorts `32214/30837`, and three
  Ready endpoints. All certificates were Ready. Argo CD, Echo, Vaultwarden,
  and the Medusa storefront returned HTTPS 200 with successful TLS validation;
  the Medusa API root returned its expected 404; and all five HTTP endpoints
  redirected with 301. A live Vaultwarden user login and authenticated revision
  read returned HTTP 200. Medusa passed a PostgreSQL transaction/rollback,
  Redis set/get/delete, and uploads-PVC create/read/delete probe.
  A temporary privileged client established an OpenVPN tunnel directly to
  `132.145.20.152:1194`, acquired `192.168.255.6`, and reached
  `192.168.255.1` with zero packet loss. However, the generated client profile
  names `ovpn.everk8s.duckdns.org`, which currently resolves to ingress address
  `130.162.161.246` rather than the OpenVPN load balancer and cannot establish
  the tunnel. The temporary client pod and sensitive profile files were deleted.
  This user-facing endpoint mismatch leaves the complete functional gate open.
  The Argo CD 3.5.0 client reported both repositories `Successful` and all five
  Applications Healthy/Synced at their recorded revisions. The Terraform-owned
  Bootstrap Seed remains auto-prune/self-heal, both repository registrations
  remain Secret-based under their original owners, Explicit Secrets were not
  changed, and all four child Applications remain manual.
- The risk owner prospectively authorized uninterrupted execution through
  `10.2.3/3.5.0`, so authorization was not bound to the subsequently generated
  plan hashes. The first acceptance item remains open to record that process
  deviation. Approval Gate 2 is prepared for human review but is not approved:
  control-plane planning remains unauthorized until the human records the Gate
  2 decision against this exact evidence and current no-change plan. The Gate 2
  decision must also resolve the OpenVPN published-endpoint mismatch; successful
  direct load-balancer connectivity is not being treated as a substitute.
- After the published OpenVPN endpoint was repaired and Gate 6 later passed,
  the human risk owner explicitly accepted the two remaining historical Gate 2
  deviations: prospective rather than exact-plan-bound authorization and the
  missing contemporaneous per-release upgrade-note evidence. This closure
  disposition does not retroactively mark those unmet controls as satisfied or
  rewrite the execution chronology. It resolves the Gate 2 record with the
  deviations retained as residual process risk.

## Answer

Argo CD reached chart/application `10.2.3/3.5.0` through every frozen hop, all
final platform, storage, Argo, ingress, workload, backup, repository, and
functional checks ultimately passed, and Platform Terraform converged with no
changes. The later OpenVPN repair removed the live functional blocker. The risk
owner accepts the historical prospective-authorization and incomplete
per-release upgrade-note evidence deviations, so Approval Gate 2 is closed
with those exceptions preserved rather than retroactively treated as met.
