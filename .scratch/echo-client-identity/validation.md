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
DaemonSet argument list; the Service manifest remained identical. That live
staging gate later passed at chart revision
`4639d6677ae81ca47eb52ecf72c1ac5cbba68986`: all four ready F5 pods
generated exactly one of each dedicated header overwrite, and the app rolled
out afterward through Argo CD. The restricted staging record is
`/private/tmp/echo-id-deploy-evidence/staging-2026-10-10.md`.

The original implementation preparation passed the following checks. Its
publication and later staging are recorded separately above.

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
`platform.tfvars` was unchanged at that stage. The later validation-only
tightening of the zero-length-CIDR check does not change these rendered values.
The preview was not used for deployment.

## Live activation

Echo `v0.0.4` is running as Linux ARM64 image digest
`sha256:5dfc2d5be2f1f23748c9d3ed4bf4403a61e835481bf343a2fa971e8f16a150ca`.
Argo CD reports `echo-app` Synced/Healthy at chart revision
`4639d6677ae81ca47eb52ecf72c1ac5cbba68986`.

The owner authorized the shared PROXY cutover after reporting all four
authenticated post-stage checks passed. The existing protected `platform.tfvars`
now persists `nginx_proxy_protocol_enabled=true` and
`nginx_lb_trusted_cidrs=["10.0.8.0/24"]` while retaining F5 chart 2.6.4 and
snippets. The fresh, full saved plan checksum is
`b8cdd462d9ca7854360a25fdf9ebfd686f0bbea52756979ff506777a61e59832`.
It proposed only one in-place `helm_release.nginx_ingress` update and a
dependent Service read, with 0 adds and 0 destroys. Terraform applied that
exact plan successfully.
A subsequent full plan with the persisted values returned no changes.

Both OCI listeners report backend PROXY version 2. All four F5 pods are ready;
each generated configuration contains PROXY listeners, the private LB trust
range and exactly two dedicated echo header overwrites. The ingress Service
retains UID `58c1cac1-b701-4351-8c20-bacf827ce3a0` and public IP
`130.162.161.246`. Both OCI backend sets report OK and the Service has four
ready endpoints. F5 logs show each ConfigMap update without error. OCI emitted
one transient concurrent-operation Service warning during reconciliation; its
final state is ACTIVE and healthy.

An independent public-IP lookup returned `87.200.19.111`; labelled public GET,
POST, ping, missing-message and invalid-JSON requests all returned their
expected bodies and logged `clientIp=87.200.19.111`, valid `clientPort`, and
the ingress connection in `remoteAddr`. A request with duplicate forged
dedicated headers and forged ordinary forwarding headers logged the true
public identity. A controlled curl source port `55040` was logged as
`clientPort=55040`, distinct from destination port 443. Public TLS/HTTP checks
passed for Argo CD, echo, Vaultwarden and relay portal; the relay WSS root
retained its baseline 404, HTTP port 80 redirected all five hosts with 301,
and WebSocket Upgrade returned 101. No ACME
HTTP-01 challenge was active. The owner reported all four authenticated
post-cutover checks passed: Argo CD and Vaultwarden reads, relay portal login,
and an application-level relay WebSocket exchange.

The ingress code uses the agreed trust of internal subnet callers; this is not
an authenticated identity guarantee against compromised internal workloads.
