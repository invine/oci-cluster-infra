# Source from https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/containerengine_node_pool

resource "oci_containerengine_node_pool" "oke-node-pool" {
  # Required
  cluster_id         = oci_containerengine_cluster.k8s_cluster.id
  compartment_id     = oci_identity_compartment.k8s_compartment.id
  kubernetes_version = var.kubernetes_version
  name               = "${oci_containerengine_cluster.k8s_cluster.name}-${var.pool_name}"
  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.vcn-private-subnet.id
    }
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[1].name
      subnet_id           = oci_core_subnet.vcn-private-subnet.id
    }
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[2].name
      subnet_id           = oci_core_subnet.vcn-private-subnet.id
    }
    size = var.node_pool_size

    node_pool_pod_network_option_details {
      #Required
      cni_type       = var.cluster_cluster_pod_network_options_cni_type
      pod_subnet_ids = [oci_core_subnet.vcn-private-subnet.id]
    }
  }
  node_shape = var.worker_node_shape
  node_shape_config {
    memory_in_gbs = var.worker_node_memory
    ocpus         = var.worker_node_ocpus
  }

  # Using image Oracle-Linux-7.x-<date>
  # Find image OCID for your region from https://docs.oracle.com/iaas/images/ 
  node_source_details {
    image_id    = data.oci_containerengine_node_pool_option.k8s_node_pool_option.sources[0].image_id
    source_type = "IMAGE"
  }

  # Optional
  initial_node_labels {
    key   = "name"
    value = oci_containerengine_cluster.k8s_cluster.name
  }

  ssh_public_key = tls_private_key.worker_node_ssh_key.public_key_openssh

}

data "oci_core_images" "worker_node_instance_images" {
  compartment_id           = oci_identity_compartment.k8s_compartment.id
  operating_system         = var.worker_node_os
  operating_system_version = var.worker_node_os_version
  shape                    = var.worker_node_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_containerengine_node_pool_option" "k8s_node_pool_option" {
  #Required
  node_pool_option_id = oci_containerengine_cluster.k8s_cluster.id

  #Optional
  compartment_id = oci_identity_compartment.k8s_compartment.id
}
