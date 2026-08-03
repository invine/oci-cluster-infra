# Keep the Velero backup store external to the cluster lifecycle

The private OCI Object Storage bucket used by Velero is an External Backup Store: it is provisioned before cluster installation, placed outside the Terraform-managed cluster compartment, and excluded from Infrastructure State and Platform State. Terraform configures Velero with the bucket name and Object Storage namespace but never creates, adopts, changes, or destroys the bucket, because backups must survive deletion and recreation of the entire cluster compartment.
