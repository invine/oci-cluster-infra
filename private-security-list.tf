# Source from https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_security_list

resource "oci_core_security_list" "private-security-list" {

  # Required
  compartment_id = oci_identity_compartment.k8s_compartment.id
  vcn_id         = module.vcn.vcn_id

  # Optional
  display_name = "${var.name_prefix}private-${var.security_list_name}"

  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }

  ingress_security_rules {
    stateless   = false
    source      = var.public_subnet_cidr
    source_type = "CIDR_BLOCK"
    # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml TCP is 6
    protocol = "6"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = var.private_subnet_cidr
    source_type = "CIDR_BLOCK"
    protocol    = "all"
    description = "Allow all incoming traffic from nodes"
  }

  ingress_security_rules {
    stateless   = false
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
    # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml ICMP is 1  
    protocol = "1"

    # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
    icmp_options {
      type = 3
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = var.public_subnet_cidr
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    tcp_options {
      min = 10250
      max = 10250
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = var.public_subnet_cidr
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    # protocol    = "all"
    tcp_options {
      min = 30000
      max = 32767
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = var.public_subnet_cidr
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    # protocol    = "all"
    tcp_options {
      min = 10256
      max = 10256
    }
  }

}
