# Cluster Reconciliation

The language used to classify cluster resources and assign each durable resource to exactly one infrastructure-as-code owner.

## Language

**Live State**:
The OCI and Kubernetes resources currently observed in the running environment, regardless of how they were created.
_Avoid_: Desired state, declared state

**Infrastructure**:
The OCI resources that provide the network and OKE cluster substrate. Infrastructure is owned by Terraform.
_Avoid_: Shared platform service, application workload

**Shared Platform Service**:
A cluster service used across applications or for cluster-wide operations. Shared platform services and their supporting configuration are owned by Terraform.
_Avoid_: Application workload, add-on

**External Backup Store**:
A private OCI Object Storage bucket supplied before cluster installation and retained independently of the cluster lifecycle so backups survive cluster deletion and recreation.
_Avoid_: Terraform-managed backup bucket, cluster-owned bucket

**Application Workload**:
A deployable application and the Kubernetes resources dedicated to it, including its namespace. Application workloads are owned by Argo CD.
_Avoid_: Shared platform service, platform foundation

**Application Namespace**:
A namespace dedicated to an application workload. It is declared explicitly in the root Argo CD bootstrap graph and adopted in place when it already exists; Terraform may place explicit secrets inside it but does not own its lifecycle.
_Avoid_: Terraform-managed namespace, implicitly created namespace

**Terraform-Managed Resource**:
A resource whose lifecycle is represented by both Terraform configuration and the authoritative Terraform state.
_Avoid_: Resource present only in configuration, resource present only in state

**Infrastructure State**:
The authoritative local Terraform state stored at the repository root for resources declared by the `infra` root module.
_Avoid_: Platform state, backend metadata

**Platform State**:
The authoritative local Terraform state stored with the `platform` root module for shared platform services, the Bootstrap Seed, and Explicit Secrets. It remains separate from Infrastructure State.
_Avoid_: Infrastructure state, application workload state

**Argo-Managed Resource**:
A resource reachable from the Argo CD bootstrap graph and tracked by an Argo CD Application. Ownership is independent of sync policy: the root bootstrap Application reconciles automatically, while child Applications require manual sync. A manifest merely present in Git is not Argo-managed.
_Avoid_: Unreachable manifest

**Generated Resource**:
A resource created by Kubernetes, OCI, or a controller as a consequence of a managed parent resource. Its lifecycle follows that parent rather than receiving a second IaC owner.
_Avoid_: Unmanaged resource, ownership gap

**Ownership Gap**:
A durable live resource that has neither Terraform nor Argo CD as its lifecycle owner. Each ownership gap must be identified and given an explicit disposition before reconciliation changes are made.
_Avoid_: Generated resource, drift

**Disposition**:
The explicit decision that classifies a live resource as Terraform-managed, Argo-managed, generated, intentionally external, or a removal candidate.
_Avoid_: Automatic adoption, implicit ownership

**Secret Value Authority**:
Sensitive Terraform variable inputs are the authoritative input for explicit secret values. Terraform materializes explicit Kubernetes Secret objects, while Argo CD references them by name and never carries their values.
_Avoid_: Kubernetes as source of truth, Git-stored secret, Argo-managed secret value

**Explicit Secret**:
A Kubernetes Secret whose value is deliberately supplied for a shared platform service or application workload. Explicit secrets are owned by Terraform; controller-created credentials and certificates are generated resources instead.
_Avoid_: Generated secret, Argo-managed secret

**Repository Registration**:
An Argo CD repository declaration containing non-sensitive connection metadata such as repository URL, type, and project. The bootstrap repository registration is Terraform-managed because it is a bootstrap prerequisite; downstream registrations, including the existing `repo-1559886016`, are adopted in place and owned by the root Argo CD bootstrap Application.
_Avoid_: Repository credential, explicit secret

**Bootstrap Seed**:
The Terraform-managed root `argocd-bootstrap` Application created after Terraform installs Argo CD. It is the sole bridge from Terraform into the Argo CD bootstrap graph and is not managed by that graph itself.
_Avoid_: Child Application, self-managed root Application

**Workload Project**:
The Argo CD `application-workloads` AppProject used by child Applications. It permits only the declared application repositories, Application Namespaces, and the shared `velero` namespace for Workload Backup Schedules, and it grants no cluster-scoped resource kinds; the Bootstrap Seed alone continues to use Argo CD's generated `default` project.
_Avoid_: Default project, platform authorization

**Workload Backup Schedule**:
A Velero Schedule dedicated to one Application Workload, owned and manually synchronized with that workload even though it resides in the shared `velero` namespace.
_Avoid_: Shared platform backup schedule, Terraform-managed backup schedule

**Secret Rotation**:
A deliberate change to an Explicit Secret through Terraform, followed by a manual restart and verification of each affected Argo-managed workload. Terraform does not mutate the workload to force adoption of the new value.
_Avoid_: Automatic workload restart, implicit rotation

**Secret Adoption**:
The transfer of an existing live Explicit Secret into Terraform configuration and state without changing its name or value. Adoption is complete only when Terraform reports no Secret data change before the first apply.
_Avoid_: Secret rotation, recreation

**Local Sensitive Artifact**:
A local Terraform variable file, state file, state backup, or saved plan that can disclose an explicit secret. Local sensitive artifacts are excluded from Git, restricted to the current user, and created under a restrictive process umask.
_Avoid_: Ordinary project file, tracked configuration example
