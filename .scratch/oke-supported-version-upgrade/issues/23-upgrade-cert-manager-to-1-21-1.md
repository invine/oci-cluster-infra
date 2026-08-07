# 23 — Upgrade cert-manager to 1.21.1

**What to build:** Move production cert-manager through every approved minor to `v1.21.1` while preserving certificate issuance and all existing TLS endpoints.

**Blocked by:** 22 — Upgrade Velero to 1.18.1

**Status:** resolved

- [x] Helm ownership of the installed CRDs is confirmed before the first live hop.
- [ ] Each minor and matching CRD change has a separately reviewed full plan and explicit human authorization. The risk owner prospectively authorized the final two hops before their saved-plan hashes existed, so the stricter exact-artifact approval requirement remains an explicitly accepted deviation.
- [x] The exact sequence through `v1.17.4`, `v1.18.6`, `v1.19.6`, `v1.20.3`, and `v1.21.1` is followed without combining or substitution.
- [x] After every hop, controller, cainjector, webhook, and startup API check are ready.
- [x] The ClusterIssuer and every Certificate remain Ready, and all declared HTTP/TLS endpoints succeed.
- [x] No Explicit Secret rotation or unrelated plan change occurs.
- [x] A failed CRD, webhook, certificate, endpoint, or plan gate pauses progression.

## Comments

- Production execution on 2026-08-08 followed the frozen sequence exactly:
  `v1.16.1 → v1.17.4 → v1.18.6 → v1.19.6 → v1.20.3 →
  v1.21.1`. Every hop used a separate full Platform plan that changed only
  `helm_release.cert_manager` in place with zero additions and zero
  destructions. The approved plan SHA-256 values were
  `262522216f6fd81603654ad835e3e4eab3a7f2288685fd50b8802159bd175453`
  for `v1.17.4`,
  `9d7df7128544310e90b8ed1a5a9224f3405c25cd39f22307a04081dac0c4942f`
  for `v1.18.6`,
  `b23d63221f2c3c191e14ec31f72a0dfa73aa586651ff329622fc4564d90c4c1f`
  for `v1.19.6`,
  `31fd0058fa46a645962218d2a1938c3b3a4590bcdb757eae57f0f82a588cd0b9`
  for `v1.20.3`, and
  `100fd0da9a120274a51188ab27c23aa7d7b89c1e4a8acfe30acb1cf9da3e6770`
  for `v1.21.1`.
- Before the first hop, all six CRDs were Established, present in the Helm
  manifest, and owned by release `cert-manager` in namespace `cert-manager`.
  The first plan replaced the deprecated `installCRDs=true` value with
  `crds.enabled=true`; every later release retained that Helm-managed CRD
  lifecycle. Protected pre-hop resource backups were stored outside the
  repository with SHA-256
  `a9550be9eaa752a9c78558229ade9e1f5ff5e11604da7bf151f47bb9b3ad682d`
  before both the `v1.17.4` and `v1.18.6` hops and
  `25f10559ea970f63516d53c1a07bd8bb6a22d169007530a33a2c4c0a27511dbb`
  in fresh captures before each of the `v1.19.6`, `v1.20.3`, and `v1.21.1`
  hops after the expected `v1.18.6` cleanup. Identical hashes reflect stable
  resource content, not reuse of one capture.
- The `v1.18.6` hop applied the documented default revision-history behavior:
  historical CertificateRequests were garbage-collected from 26 objects to
  the latest five. Those retained requests and their five controller-owned
  Orders remained Ready or valid. No Certificate was reissued; all five
  certificate expiry times and served serials remained unchanged.
- The `v1.19.6` and `v1.20.3` hops installed the restricted aggregate RBAC:
  `cert-manager-edit` no longer grants Challenge creation or Order creation,
  patch, or update. Repository and live preflight found no direct
  Order/Challenge tooling or binding that depended on the removed verbs.
  The `v1.21.1` hop then removed the unused controller token-request Role and
  RoleBinding; no Issuer used that undocumented ServiceAccount pattern, and
  no removed metrics override or disabled renewal policy was configured.
- The first post-`v1.19.6` convergence plan stopped on a Kubernetes API TCP
  reset before producing a plan. Health was refreshed and the retry, SHA-256
  `b64cd83b80154b40bbb17bf3a8c9727d07110c840f99c4e9e7e35aae479b95af`,
  reported no changes before progression resumed.
- The `v1.20.3` apply updated the live release and all three component images
  but timed out while writing Helm revision 5, leaving it
  `pending-upgrade`. Progression stopped. The pending release record was
  preserved outside the repository with SHA-256
  `13e1ec3f71de28af58f0b303e729ee395d8ab2748389a5e02884764859688964`.
  A dry-run proved that rolling revision 5 back to itself would preserve the
  already-live `v1.20.3` chart and values. That same-version forward repair
  created deployed revision 6 without downgrading or deleting Helm history;
  its complete exit gate and follow-up full plan then passed.
- After every hop, the controller, cainjector, and webhook Deployments were
  1/1 on the exact destination images; all CRDs remained Established and
  Helm-owned; webhook CA bundles and endpoints were populated; the
  `cmctl check api` command passed; the ClusterIssuer and all five Certificates
  were Ready; and
  component logs stabilized without continuing reconciliation, admission,
  injection, or TLS failures. One-shot readiness warnings belonged to replaced
  webhook pods during rolling updates and did not recur on the destination
  pods.
- The startup API hook resources in every retained Helm revision used
  `hook-succeeded` deletion, so no completed Job remained to inspect. As the
  runbook's prescribed substitute, retained Helm notes for revisions 2 through
  7 reported the exact destination release deployed successfully, including
  both the interrupted and repaired `v1.20.3` revisions, and the post-hop
  `cmctl check api --wait=2m` result was successful after every destination.
- Every declared endpoint preserved its baseline behavior under normal TLS
  verification: Argo CD, echo, and Vaultwarden returned HTTPS 200; the Medusa
  API root returned its expected 404; the Medusa storefront root returned its
  expected 307; and HTTP continued to redirect with 301. Certificate subjects,
  SANs, issuers, serials, and expiries remained unchanged. The ACME account
  Secret data hash remained
  `f4a18f5294e885693ff5b07f8306d1f4baa4d8c7e858dda79f7d8b3ebf66e379`.
- The human risk owner explicitly authorized the exact `v1.17.4`, `v1.18.6`,
  and `v1.19.6` plans, then authorized all remaining serial version changes
  without additional approval pauses. The `v1.20.3` and `v1.21.1` plans were
  still generated, hashed, and mechanically reviewed separately before their
  applies, but their authorization was prospective rather than bound to a
  plan hash. The human subsequently reviewed and approved this resolution
  record with that approval-timing deviation stated explicitly.
- Final live state is Helm revision 7, chart/application/images `v1.21.1`.
  The final full Platform plan reports `No changes` with SHA-256
  `ed427ec5fa7520f99f24b627b7ff9394797a0dc472e545819bdceeb40e6d4f54`.
  Terraform formatting and both root-module validations passed, and the full
  repository test suite passed 12 tests and 54 assertions.

## Answer

cert-manager is upgraded in production through every frozen minor to
`v1.21.1`. Helm continues to own and upgrade all six CRDs, certificate issuance
and every declared TLS endpoint remain healthy, no Certificate or account key
rotated, and Platform Terraform is converged with no remaining changes. The
only interrupted hop was `v1.20.3`; its Helm metadata timeout was recovered by
a same-version forward repair without a downgrade or release-history deletion.
The accepted residual process deviation is that authorization for the final
two saved plans was prospective rather than bound to their exact hashes, so the
matching acceptance item intentionally remains open.
