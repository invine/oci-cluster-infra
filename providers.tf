terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 4.49.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.16.1"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }

  backend "local" {
    path = "./terraform.tfstate"
  }

  #   backend "http" {
  #     address       = "https://objectstorage.uk-london-1.oraclecloud.com/p/-5W594GQZfidDsojX4lW0zDfqw-1gQVOKKfT79BWQv1kxATW3MpJEktBeCYOBN3g/n/lrlcnd1k6brl/b/terraform-bucket/o/terraform.tfstate"
  #     update_method = "PUT"
  #   }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

provider "helm" {
  kubernetes {
    config_path = local_file.k8s_cluster_kube_config_file.filename # Path to your kubeconfig
  }
}

provider "kubernetes" {
  config_path = local_file.k8s_cluster_kube_config_file.filename
}

provider "null" {}

provider "kubectl" {
  config_path = local_file.k8s_cluster_kube_config_file.filename
}
