resource "oci_containerengine_cluster" "k8s_cluster" {
  compartment_id     = oci_identity_compartment.k8s_compartment.id
  kubernetes_version = var.kubernetes_version
  name               = "${var.name_prefix}${var.kubernetes_cluster_name}"
  vcn_id             = module.vcn.vcn_id

  cluster_pod_network_options {
    #Required
    cni_type = var.cluster_cluster_pod_network_options_cni_type
  }
  endpoint_config {
    is_public_ip_enabled = var.kubernetes_public_ip_enables
    subnet_id            = oci_core_subnet.vcn-public-subnet.id
  }

  options {
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }
    kubernetes_network_config {
      pods_cidr     = var.k8s_pods_cird
      services_cidr = var.k8s_services_cird
    }

    service_lb_subnet_ids = [oci_core_subnet.vcn-public-subnet.id]
  }
}
