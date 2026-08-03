# OCI Cluster Infrastructure

This repository provisions an OCI Kubernetes Engine cluster and its shared Kubernetes platform.

Terraform 1.12 or newer is required.

## Ownership

- `infra/` owns OCI networking, OKE, and node pools. Its local Infrastructure State is `terraform.tfstate` at the repository root.
- `platform/` owns shared platform services, the Argo CD Bootstrap Seed, and Explicit Secrets. Its local Platform State is `platform/terraform.tfstate`.
- [k8s-charts](https://github.com/invine/k8s-charts) contains the Argo-managed Application Namespaces and Application Workloads.
- The private Velero Object Storage bucket is an External Backup Store. It is not owned by either Terraform state and must outlive the cluster compartment.

Only the Bootstrap Seed syncs automatically. Child Applications are reviewed and synchronized manually in Argo CD.

## Local sensitive files

Copy the tracked examples and populate the real files locally:

```sh
cp infra.example.tfvars infra.tfvars
cp platform.example.tfvars platform.tfvars
chmod 600 infra.tfvars platform.tfvars
```

Real tfvars, state files, state backups, saved plans, and generated kubeconfigs are excluded from Git. Run Terraform through `scripts/terraform-local`, which enforces `umask 077`.

## External backup prerequisite

Before installing the cluster, create a private OCI Object Storage bucket for Velero in a compartment whose lifecycle is independent of the cluster compartment. Populate `velero_backup_bucket_namespace` in `platform.tfvars`; `velero_backup_bucket_name` defaults to `k8s-velero-backup`.

Terraform passes the bucket name and Object Storage namespace to Velero but does not create, import, modify, or destroy the bucket. Preserve the bucket and its access policy when destroying or rebuilding the cluster.

## New-cluster installation

```sh
./scripts/terraform-local -chdir=infra init
./scripts/terraform-local -chdir=infra apply -var-file=../infra.tfvars

./scripts/terraform-local -chdir=platform init
./scripts/terraform-local -chdir=platform apply -var-file=../platform.tfvars
```

The platform apply installs Argo CD with Helm, creates its bootstrap Repository Registration and Bootstrap Seed, waits for Argo CD to create the Application Namespaces, and then creates Explicit Secrets. Child Applications remain unsynchronized until a human syncs them.

For an existing cluster, follow the zero-rotation import and cutover procedure in [the local cutover ticket](.scratch/cluster-three-way-reconciliation/issues/01-live-cutover.md) before applying the refactor.
