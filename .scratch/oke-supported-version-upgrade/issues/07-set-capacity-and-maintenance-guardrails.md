# Set temporary capacity and maintenance guardrails

Type: grilling
Status: resolved
Blocked by: 01, 04

## Question

What maintenance window, OCI quota/capacity prerequisites, temporary six-node cost ceiling, abort threshold, and cleanup deadline must the implementation plan enforce for the paid-capacity blue/green migration?

## Answer

Impose no special capacity, cost, maintenance, or timing guardrails beyond the upgrade's existing technical gates.

- No fixed maintenance-window duration is required. The operator may start at a convenient time and continue while the declared checks pass.
- No temporary-capacity cost ceiling is required. Short-lived paid capacity for three additional A1 workers is accepted.
- No separate OCI quota reservation or capacity preapproval is required. OCI successfully creating three replacement workers is itself the capacity gate.
- Do not cordon or drain an old worker until all three replacement workers exist, are `Ready`, use the exact approved Kubernetes version and matching OKE image, and have the required platform DaemonSets ready.
- No duration-based abort threshold is required. A failed backup, provisioning, health, storage, scheduling, or functional gate stops progression regardless of elapsed time.
- No calendar cleanup deadline is required. Remove the old worker pool immediately after the Migration Acceptance Gate passes, as already decided.

These choices remove bespoke financial and scheduling limits; they do not weaken the fresh-backup gate, the Migration Acceptance Gate, or worker-only rollback.
