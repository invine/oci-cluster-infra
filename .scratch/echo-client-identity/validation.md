# Validation: 2026-10-10

## Correction after live controller rejection

The original Helm render and isolated NGINX test did not validate F5's Ingress
annotation parser. During ticket 05, the live controller rejected the
`nginx.org/proxy-set-headers` values containing `$` and removed the echo route.
Those earlier chart checks are superseded. The local correction uses F5's
`nginx.org/location-snippets` annotation and a separately enabled
`controller.enableSnippets` setting. Helm lint and enabled/default renders,
Terraform formatting and validation, and `nginx -t` with the cached F5 5.5.4
image passed for the corrected directives. Rendering the cached F5 chart 2.6.4
with the captured baseline values and then `controller.enableSnippets=true`
changed only `-enable-snippets=false` to `-enable-snippets=true` in the
DaemonSet argument list; the Service manifest remained identical. Controller
acceptance and generated
configuration on every ready pod remain a mandatory live staging gate after
explicit authorization; no production change was made for this correction.

Implementation preparation passed the following checks. Nothing was published
or applied to production.

| Check | Result |
| --- | --- |
| Echo `go test -race ./...` | Pass: trusted/untrusted IPv4/IPv6 peers, mapped IPv4, absent/malformed/duplicate metadata, forwarding-header spoof attempts, optional-port handling, every existing request-log branch, preserved responses and `remoteAddr`. |
| Echo `go vet ./...` | Pass. |
| Echo Linux ARM64 cross-build | Pass using the final source. |
| `terraform -chdir=platform validate` | Pass on final configuration. |
| Terraform formatting and three-repo `git diff --check` | Pass. |
| Echo Helm lint, default and enabled values | Pass. |
| Echo active Argo-parameter rendering | Pass: new image pin, private trusted CIDR, exact dedicated header overwrites. Defaults disable identity; enabling without trusted CIDRs fails rendering. |
| F5 chart 2.6.4 before/after rendering | Pass: only the Service PROXY-v2 annotation and native ConfigMap entries change. Resource identities, Service traffic policy and DaemonSet are preserved. |
| Full read-only platform plan with feature enabled | 0 add, 1 in-place change, 0 destroy. Only `helm_release.nginx_ingress` updates; its dependent Service data source is read. No DNS or Explicit Secret action. |
| Isolated F5 NGINX → final echo binary | Pass: actual PROXY v1/v2 frames, IPv6 source, forged duplicate HTTP identity headers, UNKNOWN metadata, pre-PROXY ordinary HTTP and unavailable source port. |

The local integration test used `nginx/nginx-ingress:5.5.4`, pulled as digest
`sha256:379143154a02d16e4b7d56ad505636bdf73b2c190825ef023c803958ba5eb57c`.
It ran with Docker networking disabled, a read-only fixture mount and a small
temporary memory filesystem. The fixture and Go harness are retained in
`evidence/nginx-test.conf` and `evidence/proxy-check.go`; this exercises NGINX
protocol/header behavior, not the OCI controller's production reconciliation.

The private preview plan is `evidence/platform.tfplan`, SHA-256
`12c79a7e1faca83237d5cd4d8d8a7dbca2b05a6f98666d9f79b6affedcfdd45e`.
It was generated with explicit enable/CIDR command-line overrides. Local
`platform.tfvars` remains unchanged. The later validation-only tightening of
the zero-length-CIDR check does not change these rendered values. Regenerate a
fresh full plan after persisting approved settings and completing release and
live preflight; this preview is not deployment approval.

## Outstanding live checks

- Publish and verify the reviewed echo `v0.0.4` image and chart revision.
- Inspect actual OCI listener/backend/health-check configuration and confirm
  source CIDRs against Live State.
- Verify F5 accepts the Ingress annotation on every instance before enabling
  the app's header consumption.
- Execute the separately approved maintenance rollout and verify public source
  identity, spoof resistance, optional source port and all shared endpoints.

The ingress code uses the agreed trust of internal subnet callers; this is not
an authenticated identity guarantee against compromised internal workloads.
