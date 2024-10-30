# Source from https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/identity_availability_domains

# Tenancy is the root or parent to all compartments.

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}
