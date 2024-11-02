module "vcn" {
  source         = "oracle-terraform-modules/vcn/oci"
  version        = "3.6.0"
  compartment_id = oci_identity_compartment.k8s_compartment.id
  region         = var.region

  vcn_name      = "${var.name_prefix}${var.vcn_name}"
  vcn_dns_label = var.vcn_dns_label
  vcn_cidrs     = [var.vcn_cidr]

  create_internet_gateway = true
  create_nat_gateway      = true
  create_service_gateway  = true
}
