# Echo client identity: release package

Prepared 2026-10-10 for ticket [04](issues/04-publish-verified-echo-release.md).
This is a review record for publication; it is not authorization to push,
publish, merge, sync Argo, apply Terraform or change production resources.

## Reviewed candidates

| Item | Local candidate | Release state |
| --- | --- | --- |
| Echo source | `81bc06dfb5081b748f33adc1f5b01b939e06b60d` on `codex/echo-client-identity` | Qualified by ticket 02; not yet tagged or published. |
| Echo image | `ghcr.io/invine/echo:v0.0.4` | Tag and GHCR image were absent at preparation time. Registry digest and platform verification are pending. |
| Chart and active root child Application | `d256b1860ea751f6a3e28d2662007cb19f96af50` on the chart integration branch | Local candidate only. Record the published chart commit after review and merge. |
| Infrastructure | `bd312798976011b2a4d9727dda73c0e3c864df9f` | Ticket 02 qualification evidence and rollout runbook; platform activation remains separate. |

The existing echo release workflow is `.github/workflows/build-and-push.yaml`.
It runs on a pushed `v*` tag, checks out the tag source, logs into GHCR and
builds/pushes `linux/arm64` via `docker/build-push-action@v5`. Its metadata
action derives the `v0.0.4` image tag from the Git tag. Review the exact tag
target and workflow run; an ARM64 build setting alone is not registry evidence.
If `v0.0.4` becomes occupied, select and review a new immutable tag and update
the Application parameter before publication. Never replace an existing tag.

The active root child declaration is
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

These checks prove the local candidate and render, not publication, OCI
listener behavior or public traffic acceptance.

## Publication gate and required record

Review and authorize these concrete actions separately: publish the reviewed
echo source commit through the existing `v0.0.4` tag workflow, then merge or
publish the reviewed chart/Application change **only after** verifying the
image. The approval should identify the source and chart candidate commits,
the chosen tag and any merge commits or changed files. Any app or chart
implementation change after ticket 02 needs relevant requalification.

Before a tag push, verify no `refs/tags/v0.0.4` exists locally or on `origin`
and no conflicting registry image uses that tag. After a reviewed source merge,
verify the tag resolves to the qualified source tree. Confirm the GitHub
Actions run for the tag succeeded and checked out that source revision. Inspect
the GHCR artifact by immutable digest, prove it includes `linux/arm64`, and
record the digest together with tag and Git source SHA. Do not infer success
from the workflow definition or a local ARM64 binary.

Only then publish the chart candidate. Resolve the **published** chart Git SHA
and review its root child Application and chart content at that exact revision.
Record that SHA below and use it in both Argo sync commands; neither command
should use moving `main` during the rollout. The root child Application tracks
`main` but is manually synchronized. Bootstrap Seed reconciliation updates
its declaration only; it cannot itself sync echo's Ingress or Deployment.

| Release field | Verified value |
| --- | --- |
| Source SHA at tag | Pending |
| Git tag | Pending: `v0.0.4` candidate |
| Successful workflow run and source SHA | Pending |
| GHCR image digest | Pending |
| GHCR `linux/arm64` manifest | Pending |
| Published chart commit | Pending |
| Reviewed chart render at published commit | Pending |

Ticket 05 will install and verify the header overwrite before the echo
Deployment trusts it. Ticket 06 owns the platform cutover and production
acceptance. This ticket performs no Argo sync or platform/DNS/Service mutation.
