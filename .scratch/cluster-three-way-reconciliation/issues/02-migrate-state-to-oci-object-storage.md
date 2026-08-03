# Migrate Terraform states to OCI Object Storage

Status: ready-for-human

## Purpose

Replace the accepted local-state arrangement with a private OCI native backend when the owner is ready, without combining Infrastructure State and Platform State.

## Desired result

- One dedicated private, versioned Object Storage bucket protected from accidental deletion.
- Native OCI backend state locking enabled automatically.
- Oracle-managed server-side encryption; no paid Vault dependency required.
- Separate object keys for Infrastructure State and Platform State.
- Backend authentication supplied through the existing OCI configuration rather than committed backend credentials.

## Proposed keys

- `infra/terraform.tfstate`
- `platform/terraform.tfstate`

## Preconditions

- Choose a maintenance window with no concurrent Terraform operations.
- Verify Terraform 1.12 or newer.
- Create or adopt the dedicated state bucket and enable versioning.
- Restrict IAM access to the state and lock objects.
- Preserve mode-`0600` recoverable copies of both local states until migration is verified.

## Migration outline

1. Configure an `oci` backend in each Terraform root with the shared bucket and its distinct key.
2. Run `terraform init -migrate-state` through `scripts/terraform-local` for `infra`.
3. Compare the remote Infrastructure State resource list with the local source.
4. Repeat for `platform`.
5. Verify locking and a no-change plan in both roots.
6. Remove local state copies only after recovery and access tests succeed.

## References

- [Terraform OCI backend](https://developer.hashicorp.com/terraform/language/backend/oci)
- [OCI Object Storage state guidance](https://docs.oracle.com/en-us/iaas/Content/dev/terraform/object-storage-state.htm)

## Comments

- The user explicitly deferred this migration and accepted local state with mode `0600` for the current refactor.
