# Source from https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/containerengine_node_pool

locals {
  approved_worker_image_name_prefix = "Oracle-Linux-8."

  matching_worker_image_sources = {
    for generation, pool in var.worker_pools : generation => [
      for source in data.oci_containerengine_node_pool_option.worker_images.sources : source
      if source.image_id == pool.image_ocid &&
      source.source_type == "IMAGE" &&
      startswith(source.source_name, local.approved_worker_image_name_prefix) &&
      strcontains(source.source_name, "-OKE-${trimprefix(pool.kubernetes_version, "v")}-")
    ]
  }
}

data "oci_containerengine_node_pool_option" "worker_images" {
  compartment_id      = oci_identity_compartment.k8s_compartment.id
  node_pool_option_id = "all"
}

resource "oci_containerengine_node_pool" "worker_pool" {
  for_each = var.worker_pools

  cluster_id         = oci_containerengine_cluster.k8s_cluster.id
  compartment_id     = oci_identity_compartment.k8s_compartment.id
  kubernetes_version = each.value.kubernetes_version
  name               = each.value.name

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
    size = each.value.size

    node_pool_pod_network_option_details {
      cni_type       = var.cluster_cluster_pod_network_options_cni_type
      pod_subnet_ids = [oci_core_subnet.vcn-private-subnet.id]
    }
  }

  node_shape = var.worker_node_shape
  node_shape_config {
    memory_in_gbs = var.worker_node_memory
    ocpus         = var.worker_node_ocpus
  }

  node_source_details {
    image_id    = each.value.image_ocid
    source_type = "IMAGE"
  }

  initial_node_labels {
    key   = "name"
    value = oci_containerengine_cluster.k8s_cluster.name
  }

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true

    precondition {
      condition     = length(local.matching_worker_image_sources[each.key]) == 1
      error_message = "Worker pool ${each.key} image_ocid must resolve to an available ${local.approved_worker_image_name_prefix}x OKE image for Kubernetes ${each.value.kubernetes_version}."
    }
  }

  ssh_public_key = tls_private_key.worker_node_ssh_key.public_key_openssh
}

moved {
  from = oci_containerengine_node_pool.oke-node-pool-bluegreen[0]
  to   = oci_containerengine_node_pool.worker_pool["v1.34.2"]
}
