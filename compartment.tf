resource "oci_identity_compartment" "k8s_compartment" {
  # Required
  compartment_id = var.tenancy_ocid
  description    = var.compartment_description
  name           = "${var.name_prefix}${var.compartment_name}"
}
