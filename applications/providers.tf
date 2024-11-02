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
  }

  backend "local" {
    path = "../terraform.tfstate"
  }
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

provider "kubernetes" {
  config_path = local_file.k8s_cluster_kube_config_file.filename
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}
