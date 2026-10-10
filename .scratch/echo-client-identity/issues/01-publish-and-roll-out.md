# Publish and roll out echo client identity

Status: ready-for-human

The user confirmed the design and authorized implementation preparation, not a
production rollout. Code and a full read-only platform plan are prepared.

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
