# 35 — Prepare Gate 1 plan remediation

**What to build:** Make Gate 1 machine-checkable and reconcile the configuration contracts exposed by the failed plan, without changing Infrastructure State, Platform State, or Live State.

Type: task
Blocked by: 19
Status: resolved

- [x] Each `worker_pools` entry declares an explicit `candidate` or `retained` disposition; the existing `v1.34.2` pool is retained and the future `v1.36.1` pool is candidate.
- [x] Every worker pool fails closed unless its refreshed OCI pool identity, pinned image OCID, source type, source name, exact Kubernetes version, and approved Oracle Linux family match its declaration.
- [x] Candidate Worker Pools additionally require exactly one match in OCI's currently available worker-image catalog; Retained Worker Pools do not fail solely because their matching pinned image has retired from that catalog.
- [x] The NGINX LoadBalancer configuration explicitly sets OKE security-list management mode to `None` without changing the release, Service identity, selectors, LoadBalancer settings, addresses, ports, chart, or application version.
- [x] A Gate 1 validator consumes a saved full Infrastructure plan plus fresh captured evidence, records the plan SHA-256, and emits no kubeconfig, certificate, credential, OCID, or other sensitive value.
- [x] The validator canonicalizes OCI security rules and permits only semantic removal of any still-present subset of the three initially captured NGINX Service port rules from each relevant security list; it rejects any other rule addition, removal, broadening, narrowing, or change.
- [x] The validator permits kubeconfig replacement only when endpoint, certificate authority data, cluster OCID, region, authentication command and arguments, and output path are unchanged, the resulting mode is `0600`, and content differences are limited to internally consistent aliases.
- [x] The validator proves that the retained pool's OCI pool OCID, name, size, version, shape, placement, labels, SSH key, and image are unchanged and rejects every resource action outside the Gate 1 allowlist.
- [x] Non-sensitive positive and negative fixtures prove that the validator accepts the approved shape and rejects meaningful kubeconfig changes, pool identity changes, non-allowlisted security changes, and unrelated resource actions.
- [x] The operator runbook and evidence template describe the prerequisite Platform apply, rollback, saved-plan hash and identity rule, validator invocation, exact Infrastructure allowlist, and no-change follow-up plan.
- [x] Terraform formatting and non-mutating validation, validator fixture checks, documentation/link checks, and `git diff --check` pass.
- [x] No Terraform plan, apply, import, state command, OCI or Kubernetes mutation, Argo sync, production restart, or other Infrastructure State, Platform State, or Live State mutation is performed.

## Answer

Implemented the configuration-only Gate 1 remediation. Worker pools now declare
Candidate or Retained disposition and exact image names, the ingress Service
declares Terraform-only security-list ownership, and the saved-plan validator
fails closed outside the approved pool move, redundant-rule cleanup, and
semantic kubeconfig replacement. The operator package records ticket 36 as the
separately authorized Platform prerequisite. Non-mutating validation and both
review axes pass; Infrastructure State, Platform State, and Live State were not
changed.
