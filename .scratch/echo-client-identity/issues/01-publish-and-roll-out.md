# Publish and roll out echo client identity

Status: resolved

The owner subsequently authorized the release, corrected staging and shared
PROXY cutover. The steps below were completed on 2026-10-10.

1. Review the three repository diffs and publish the tested echo `v0.0.4` image.
2. Verify its architecture/digest, then merge the chart/Application change.
3. Follow the [runbook](../../../docs/runbooks/echo-client-identity.md), including
   the Ingress-only sync before the echo Deployment starts trusting metadata.
4. Persist the feature settings in protected `platform.tfvars`, generate a fresh
   full plan, review the concrete maintenance/recovery package, and obtain
   approval before any production mutation.
5. Apply the approved change during the maintenance window and pass every live
   acceptance check. Record outcomes and resolve this issue.

The source port remains best effort. Do not claim production client identity is
fixed based only on local tests or the Terraform plan.

## Answer

Echo source `81bc06df` was published as `v0.0.4` and verified as Linux ARM64
image digest
`sha256:5dfc2d5be2f1f23748c9d3ed4bf4403a61e835481bf343a2fa971e8f16a150ca`.
Corrected chart revision `4639d6677ae81ca47eb52ecf72c1ac5cbba68986`
was synchronized through Argo CD with the Ingress verified before the echo
Deployment. A fresh full Terraform plan, SHA-256
`b8cdd462d9ca7854360a25fdf9ebfd686f0bbea52756979ff506777a61e59832`,
was applied to enable shared OCI/F5 PROXY v2. Both listeners, all four ingress
pods, backend health, public source IP and port, spoof resistance, responses,
TLS and WebSocket checks passed. The owner reported authenticated Argo CD,
Vaultwarden, relay portal and application-level relay WebSocket checks passed.
The Service UID and public IP were preserved; a post-apply full plan showed no
changes. See [validation](../validation.md) and
[ticket 06](06-activate-and-verify-client-identity.md) for the acceptance
record. Private operational evidence remains outside Git under
`/private/tmp/echo-id-deploy-evidence/`.
