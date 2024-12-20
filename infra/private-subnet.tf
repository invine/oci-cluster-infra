# Source from https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_subnet

resource "oci_core_subnet" "vcn-private-subnet" {

  # Required
  compartment_id = oci_identity_compartment.k8s_compartment.id
  vcn_id         = module.vcn.vcn_id
  cidr_block     = var.private_subnet_cidr

  # Optional
  # Caution: For the route table id, use module.vcn.nat_route_id.
  # Do not use module.vcn.nat_gateway_id, because it is the OCID for the gateway and not the route table.
  prohibit_internet_ingress  = true
  prohibit_public_ip_on_vnic = true
  route_table_id             = module.vcn.nat_route_id
  security_list_ids          = [oci_core_security_list.private-security-list.id]
  display_name               = "${var.name_prefix}private-${var.subnet_name}"
}
