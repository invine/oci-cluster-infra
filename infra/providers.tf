terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 4.49.0"
    }
  }

  backend "local" {
    path = "../terraform.tfstate"
  }

}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

provider "kubernetes" {
  config_path = local_file.k8s_cluster_kube_config_file.filename
}
