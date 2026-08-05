# Determine OKE target candidates and upgrade constraints

Type: research
Status: resolved
Blocked by: none

## Question

As of August 4, 2026, which Kubernetes versions newer than `v1.34.2` are actually available for this production OKE cluster in `uk-london-1`, and what OCI-supported control-plane hop sequence, worker version-skew rules, maintenance behavior, and non-downgrade constraints govern reaching each candidate?

## Answer

[OKE target candidates and upgrade constraints — 2026-08-04](../../../docs/research/oke-target-candidates-2026-08-04.md) records authoritative follow-up OCI results: `uk-london-1` offers Kubernetes through `v1.36.1`, while the ACTIVE production cluster on `v1.34.2` currently offers `v1.35.0` and `v1.35.2` as its next hop. Intersecting that list with the platform ceiling freezes `v1.36.1` as the target; the route starts at `v1.35.2` and must re-query OCI before advancing to `v1.36.1`.
