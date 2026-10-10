# Echo client identity: release package

**Superseded for deployment.** The published chart revision
`d256b1860ea751f6a3e28d2662007cb19f96af50` was synchronized outside the
required staging sequence. F5 rejected its `proxy-set-headers` annotation and
removed the echo route. Its release record below remains historical evidence;
do not use that chart revision for another sync or the PROXY cutover. The
corrected chart and separate F5 snippet capability required a new reviewed
release and staged authorization. The owner subsequently authorized deployment
through Terraform and Argo CD. Chart revision
`4639d6677ae81ca47eb52ecf72c1ac5cbba68986` was staged Ingress first,
then Deployment, after F5 snippets were enabled. OCI PROXY remains disabled;
see `/private/tmp/echo-id-deploy-evidence/staging-2026-10-10.md`.

Prepared and publication-verified 2026-10-10 for ticket
[04](issues/04-publish-verified-echo-release.md). Publication and the chart
merge were authorized and completed. This record does not authorize
Argo sync, Terraform apply, DNS/Service changes or production cutover.

## Reviewed candidates

| Item | Local candidate | Release state |
| --- | --- | --- |
| Echo source | `81bc06dfb5081b748f33adc1f5b01b939e06b60d` | Qualified by ticket 02; published as remote `main` and peeled annotated tag `v0.0.4`. |
| Echo image | `ghcr.io/invine/echo:v0.0.4` | Published; registry digest `sha256:5dfc2d5be2f1f23748c9d3ed4bf4403a61e835481bf343a2fa971e8f16a150ca`, `linux/arm64`. |
| Chart and active root child Application | `d256b1860ea751f6a3e28d2662007cb19f96af50` | Published as chart remote `main`; invalid for further rollout because F5 rejected its Ingress. |
| Infrastructure | `bd312798976011b2a4d9727dda73c0e3c864df9f` | Ticket 02 qualification evidence and rollout runbook; platform activation remains separate. |

The existing echo release workflow is `.github/workflows/build-and-push.yaml`.
It runs on a pushed `v*` tag, checks out the tag source, logs into GHCR and
builds/pushes `linux/arm64` via `docker/build-push-action@v5`. Its metadata
action derives the `v0.0.4` image tag from the Git tag. The
[successful workflow run](https://github.com/invine/echo/actions/runs/38055451405)
reported tag event, source SHA
`81bc06dfb5081b748f33adc1f5b01b939e06b60d`, completion and success.
The annotated tag object is `4f34280956982f4957c24026250ea0e07f97f764`;
peeling it resolves to that source commit. Never replace the published tag.

The published active root child declaration at the chart SHA above is
`argocd-bootstrap/root/applications/echo-application.yaml`. It opts into
identity with `image.tag=v0.0.4`, `clientIdentity.enabled=true` and
`clientIdentity.trustedProxyCidrs[0]=10.0.4.0/22`. It has no automated
`syncPolicy`. The separate legacy declaration under
`argocd-bootstrap/applications/` still uses `v0.0.3`; the Terraform Bootstrap
Seed points to `argocd-bootstrap/root`, so review any change to that path
before assuming the active child changed.

## Local verification

- Echo `go test -race ./...` and `go vet ./...` passed at the source SHA above.
- `GOOS=linux GOARCH=arm64 go build ./internal/cmd` produced an AArch64 ELF.
  The local binary checksum is `de5624da99fd4c56557fd5519a66a3ea24f53023e5c32bb220649f0708049265`;
  this is **not** the container image digest.
- Helm lint passed with default and active identity values. The exact active
  Application parameters rendered image `ghcr.io/invine/echo:v0.0.4`,
  `LOG_LEVEL=debug`, `TRUSTED_PROXY_CIDRS=10.0.4.0/22`, and
  `nginx.org/proxy-set-headers: X-Echo-Client-IP: $proxy_protocol_addr,X-Echo-Client-Port: $proxy_protocol_port`.
  The rendered manifest checksum is
  `4a52154f987f123c354ba02f0622ff6dbaa8450a9c9072fa9d277777640b764f`.
  The chart default omits app trust and the annotation. Rendering with
  identity enabled but no trusted CIDR fails as required.
- The app source and chart candidates have no ticket 04 implementation changes.
  Ticket 02's [qualification evidence](validation.md) remains applicable.

These local checks establish the candidate behavior and render. The remote
checks below establish publication; neither set establishes OCI listener
behavior or public traffic acceptance.

## Publication record and remaining rollout gate

The reviewed source/tag publication and chart/Application merge were approved
and completed in that order. Independent read-only checks found remote echo
`main`, the peeled tag, workflow source SHA, registry digest/platform and
remote chart `main` at the values recorded here. No app or chart implementation
changed after ticket 02 qualification.

The current tag resolves to the recorded immutable digest. The chart identifies
the reviewed `v0.0.4` tag and the digest is the registry identity for release
verification. Recheck tag-to-digest mapping before rollout; do not overwrite
the tag or silently accept a changed digest.

The **original published** chart Git SHA is
`d256b1860ea751f6a3e28d2662007cb19f96af50`. It is retained here for
audit only and must not be used for further rollout. A corrected chart revision
must be reviewed and fixed for both Argo stages; neither command should use
moving `main`. The root child Application tracks `main` but is manually synchronized.
Bootstrap Seed reconciliation updates its declaration only; it cannot itself
sync echo's Ingress or Deployment, and it cannot enable Terraform's shared LB
PROXY setting.

| Release field | Verified value |
| --- | --- |
| Source SHA at tag | `81bc06dfb5081b748f33adc1f5b01b939e06b60d` |
| Git tag | Annotated `v0.0.4`; peeled to source SHA above |
| Successful workflow run and source SHA | [38055451405](https://github.com/invine/echo/actions/runs/38055451405), success at source SHA above |
| GHCR image digest | `sha256:5dfc2d5be2f1f23748c9d3ed4bf4403a61e835481bf343a2fa971e8f16a150ca` |
| GHCR platform | `linux/arm64`, from `docker manifest inspect --verbose` of the published tag |
| Published chart commit for both sync stages | `d256b1860ea751f6a3e28d2662007cb19f96af50` |
| Reviewed chart render at published commit | SHA-256 `4a52154f987f123c354ba02f0622ff6dbaa8450a9c9072fa9d277777640b764f` |

A read-only live Application check found `echo-app` at `v0.0.3`, synced to
`1b7d20e2c09ce64a2011a82031fa0e0586ab9157`, with no automated sync
policy. The published chart revision is therefore available but has not been
synced to the workload. The infrastructure variable for shared PROXY protocol
defaults to false; the Bootstrap Seed has no ownership of that setting.

Ticket 05 installs and verifies the header overwrite before the echo Deployment
trusts it. Ticket 06 owns the platform cutover and production acceptance. This
ticket performed no Argo sync or platform/DNS/Service mutation.
