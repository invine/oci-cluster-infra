# 22 — Upgrade Velero to 1.18.1

**What to build:** Move production Velero through each approved coherent release set to application `1.18.1` while proving current backup creation and External Backup Store access after every hop.

**Blocked by:** 21 — Upgrade Longhorn to 1.12.0

**Status:** resolved

- [x] Each CRD and Helm hop has a separately reviewed full plan and explicit human authorization.
- [x] The four approved chart/application/AWS-plugin sets are applied in order without combining or substituting versions.
- [x] Exact-minor CRDs are applied before their corresponding Helm hop while automatic CRD upgrades remain disabled.
- [x] Server, node agent, restore helper, AWS plugin, and chart remain a matching set at every hop.
- [x] After each hop, the Deployment and node-agent DaemonSet are ready, the Backup Storage Location is available, and all Kopia BackupRepositories are Ready.
- [x] Fresh backups for `staging`, `vaultwarden`, and `openvpn` complete with zero errors and warnings after each hop.
- [x] No restore rehearsal occurs and no evidence claims proven restoreability.
- [x] Any failed backup, repository, CRD, rollout, or unrelated-plan check pauses progression.

## Comments

- Production execution on 2026-08-07 followed the four frozen release sets in
  order: chart/application/AWS plugin `8.7.2/1.15.2/1.11.1`,
  `10.1.3/1.16.2/1.12.2`, `11.4.0/1.17.1/1.13.2`, and
  `12.1.0/1.18.1/1.14.2`. The server, node agent, restore helper, plugin, and
  chart were checked as an exact coherent set after every apply. Helm-managed
  CRD upgrades and volume snapshots remained disabled; the node agent remained
  enabled.
- Each exact-minor CRD set was rendered from a checksum-pinned official chart,
  reviewed with a server-side diff, explicitly authorized, applied before its
  Helm hop, and verified with all thirteen CRDs Established. Manifest SHA-256
  values were `a75ffbfe040380a43bb05f1f8fb6a306514c4bcb6b3e752b386e3ef2ff104ec2`
  for `1.15.2`, `d2af0a9556a701a443c51714ba828abf0c9cd32d0daca8b91e90e1238f5da87d`
  for `1.16.2`, `70659dd18f2ac974d0b526da7a20c3a990a0808da9bf070dda7c903087fe04e1`
  for `1.17.1`, and `6d63f2ff8b0f016028fcd6907c400b1d2c361814cfb984bf198c23b4569b5554`
  for `1.18.1`.
- Every Helm change used a separately saved full Platform plan with zero
  additions and zero destructions. Approved plan SHA-256 values were
  `42ab51bcd51ea3545c2fa807c34aaf0128beb9904c469dec1dd7090446fc8c03`
  for `1.15.2`, `c32a2d33539588dd14d18bda8925d4ae59034c33b9c2483e731a7859cd4be032`
  for `1.16.2`, `1e9fd1ea024e28089cf3e22c041d66798d51aaa4e35e6ee6d0f8fea9f7825ade`
  for the authorized `1.17.1` retry, and
  `62b4985b8775d1ed7dac52287bba6d2de83d6aa3e52c07609ac051890db22149`
  for `1.18.1`. The first `1.17.1` apply, plan SHA-256
  `0e90c8d009ff0113ec56058514064175e97b6c46769db198b216dcbeeeadf631`,
  stopped on a Kubernetes API TCP reset before Helm changed the release. Live
  state was proved unchanged, a fresh full plan was reviewed, and only then was
  the retry authorized.
- The first `1.15.2` namespace backups exposed OCI Object Storage's rejection
  of AWS chunked encoding. Execution paused. A separately reviewed one-change
  recovery plan, SHA-256
  `4dd88a062955885ad79ff5dbf8d3f9a0135ca5c21534275f4d2b95002399d474`,
  configured an empty AWS-plugin `checksumAlgorithm`. The authorized retries
  then Completed with zero errors and warnings:
  `upgrade-1-15-2-staging-retry1-20260807t1850z` included only `staging` and
  completed 86/86, `upgrade-1-15-2-openvpn-retry1-20260807t1850z` included
  only `openvpn` and completed 23/23, and
  `upgrade-1-15-2-vaultwarden-retry1-20260807t1850z` included only
  `vaultwarden` and completed 50/50 between `18:49:09Z` and `18:49:31Z`.
- The `1.16.2` backups
  `upgrade-1-16-2-{staging,openvpn,vaultwarden}-20260807t1855z` Completed with
  zero errors and warnings: 59/59, 13/13, and 40/40 between `19:00:52Z` and
  `19:01:22Z`. The `1.17.1` backups
  `upgrade-1-17-1-{staging,openvpn,vaultwarden}-20260807t1909z` likewise
  Completed 59/59, 13/13, and 40/40 between `19:49:01Z` and `19:50:16Z`.
- AWS plugin `1.14.2` upgraded its AWS Go SDK and independently re-enabled the
  SDK's new default CRC32 request checksums. Consequently, the first three
  `1.18.1` backups reached their full item counts and completed all five
  PodVolumeBackups but Failed while uploading final metadata to OCI with HTTP
  501. Execution paused again. The AWS-documented compatibility setting
  `AWS_REQUEST_CHECKSUM_CALCULATION=WHEN_REQUIRED` was added alongside the
  empty plugin checksum algorithm. The separately reviewed recovery plan had
  SHA-256 `03c5aa1d2aa0f1369b0a2fab3327d3f3f3a6517c11b5342526b77bd09358ade9`
  and changed only `helm_release.velero` in place.
- After the final recovery, the live Velero container was verified with
  `AWS_REQUEST_CHECKSUM_CALCULATION=WHEN_REQUIRED`. Backups
  `upgrade-1-18-1-{staging,openvpn,vaultwarden}-retry1-20260807t2011z`
  Completed with zero errors and warnings: 59/59, 13/13, and 40/40 between
  `20:55:44Z` and `20:56:40Z`. All five associated PodVolumeBackups Completed,
  there were no Warning events, and the exact server log had no unexpected
  warning/error entries.
- The recurring plugin-process `read |0: file already closed` scanner messages
  were classified as HashiCorp go-plugin shutdown logging rather than operation
  errors; the Kopia deletion-watermark line is emitted at error level by the
  pinned source even when the maintenance function returns success. Kubernetes
  also logged an informational deprecation notice for core/v1 Endpoints. These
  diagnostics were retained rather than misreported as backup status warnings.
- Health gates were recorded after every accepted hop. At `1.15.2`, `1.16.2`,
  `1.17.1`, and `1.18.1`, respectively, the Deployment was 1/1 and the
  node-agent DaemonSet was 3/3; the Backup Storage Location was Available; and
  the staging, openvpn, and vaultwarden Kopia repositories were Ready. Each
  observation preceded the next CRD or backup mutation, and each hop ended with
  an empty full Platform plan. The final phases were captured again after all
  recovery backups.
- The human risk owner operating this Codex task explicitly approved every CRD
  checksum/diff, saved-plan SHA-256, recovery plan, and named backup set after
  its evidence was presented and before the corresponding mutation. The
  ordered task transcript is the approval record and binds each response to the
  immediately preceding exact artifact and health evidence; this issue retains
  the execution date, artifact hashes, backup identifiers, and resulting
  evidence. The approver is retained by role rather than personal identity, and
  separate wall-clock timestamps for individual chat approval messages were not
  captured, so no more precise approval-time claim is made here.
- Final live state is chart `12.1.0`, application/server/node agent/restore
  helper `1.18.1`, and AWS plugin `1.14.2`. The Deployment is 1/1, the
  node-agent DaemonSet is 3/3, the Backup Storage Location is Available, all
  three Kopia repositories are Ready, and the final full Platform plan reports
  `No changes`.
- No restore was created or attempted. The successful backup and External
  Backup Store evidence proves current backup creation, not restoreability.

## Answer

Velero is upgraded in production through every approved coherent set to chart
`12.1.0` and application `1.18.1`, with AWS plugin `1.14.2`. Every exact-minor
CRD set preceded its Helm hop, every final namespace backup completed with zero
reported errors or warnings, and Terraform has converged with no remaining
changes. OCI-compatible uploads require both an empty plugin checksum algorithm
and `AWS_REQUEST_CHECKSUM_CALCULATION=WHEN_REQUIRED`. Restoreability remains
deliberately unproven because this ticket performed no restore rehearsal.
