# Source from https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_subnet

resource "oci_core_subnet" "vcn-public-subnet" {

  # Required
  compartment_id = oci_identity_compartment.k8s_compartment.id
  vcn_id         = module.vcn.vcn_id
  cidr_block     = var.public_subnet_cidr

  # Optional
  route_table_id    = module.vcn.ig_route_id
  security_list_ids = [oci_core_security_list.public-security-list.id]
  display_name      = "${var.name_prefix}public-${var.subnet_name}"

}
