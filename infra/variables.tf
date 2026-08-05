variable "tenancy_ocid" {
  description = "The OCID of your tenancy"
  type        = string
  sensitive   = true
}

variable "user_ocid" {
  description = "The OCID of your user"
  type        = string
  sensitive   = true
}

variable "fingerprint" {
  description = "The fingerprint of your API key"
  type        = string
  sensitive   = true
}

variable "private_key_path" {
  description = "Private Key value"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "OCI region"
  type        = string
  sensitive   = true
}

variable "par_url" {
  description = "Pre-authenticated Access URL for OCI bucket to store state file"
  type        = string
  sensitive   = true
}

variable "name_prefix" {
  description = "prefix for all resource names"
  default     = "prod-"
}

variable "compartment_name" {
  description = "OCI Compartment Name"
  default     = "compartment"
}

variable "compartment_description" {
  description = "OCI Compartment Description"
  default     = "Automatically created by Terraform"
}

## Networking

variable "vcn_name" {
  description = "VCN's Name"
  default     = "vcn"
}

variable "vcn_dns_label" {
  description = "VCN's DNS Tag"
  default     = "k8svcn"
}

variable "vcn_cidr" {
  description = "VCN's CIDR IP Block"
  default     = "10.0.0.0/16"
}

variable "security_list_name" {
  description = "Name of Security List for Private Subnet"
  default     = "security-list"
}

variable "subnet_name" {
  description = "Private Subnet Name"
  default     = "subnet"
}

variable "private_subnet_cidr" {
  description = "Private Subnet CIRD"
  default     = "10.0.4.0/22"
}

variable "public_subnet_cidr" {
  description = "Public Subnet CIRD"
  default     = "10.0.8.0/24"
}

variable "instance_configuration_name" {
  description = "Display name of Instance Configuration for k8s nodes"
  default     = "node-instance-configuration"
}

variable "instance_configuration_node_instance_type" {
  description = "Instance Type for k8s nodes"
  default     = ""
}

variable "control_plane_kubernetes_version" {
  description = "Kubernetes version for the OKE control plane, independent of worker-pool versions."
  type        = string
  default     = "v1.34.2"

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+$", var.control_plane_kubernetes_version))
    error_message = "control_plane_kubernetes_version must be an exact version such as v1.34.2."
  }
}

variable "kubernetes_cluster_name" {
  description = "Kubernetes cluster name"
  default     = "cluster"
}

variable "kubernetes_public_ip_enables" {
  description = "Enable public access to kubernetes cluster"
  default     = false
}

variable "worker_pools" {
  description = "Worker pools keyed by their immutable Kubernetes generation. Each image OCID is pinned and validated against OCI's OKE image catalog."
  type = map(object({
    name               = string
    kubernetes_version = string
    size               = number
    image_ocid         = string
  }))

  validation {
    condition = alltrue([
      for generation, pool in var.worker_pools :
      generation == pool.kubernetes_version && can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+$", generation))
    ])
    error_message = "Each worker_pools key must be the same exact Kubernetes version declared by that pool."
  }

  validation {
    condition = alltrue([
      for pool in values(var.worker_pools) :
      length(trimspace(pool.name)) > 0 && pool.size > 0 && floor(pool.size) == pool.size
    ])
    error_message = "Each worker pool must have a stable non-empty name and a positive whole-number size."
  }

  validation {
    condition = alltrue([
      for pool in values(var.worker_pools) :
      can(regex("^ocid1\\.image\\.", pool.image_ocid))
    ])
    error_message = "Each worker pool must pin an OCI image OCID."
  }
}

variable "worker_node_shape" {
  description = "Worker Node instance shape"
  default     = "VM.Standard.A1.Flex"
}

variable "worker_node_ocpus" {
  description = "Number of OCPUs available to worker nodes."
  default     = 1
}

variable "worker_node_memory" {
  description = "Amount of memory available to worker nodes, in gigabytes."
  default     = 6
}

variable "cluster_cluster_pod_network_options_cni_type" {
  default = "OCI_VCN_IP_NATIVE"
}

variable "k8s_pods_cird" {
  default = "10.244.0.0/16"
}

variable "k8s_services_cird" {
  default = "10.96.0.0/16"
}

variable "duckdns_subdomain" {
  description = "DuckDNS Subdomain"
  type        = string
}

variable "duckdns_token" {
  description = "DuckDNS Token"
  type        = string
  sensitive   = true
}
