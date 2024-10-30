data "oci_containerengine_cluster_kube_config" "k8s_cluster_kube_config" {
  #Required
  cluster_id = oci_containerengine_cluster.k8s_cluster.id
}

resource "local_file" "k8s_cluster_kube_config_file" {
  content  = data.oci_containerengine_cluster_kube_config.k8s_cluster_kube_config.content
  filename = "${path.module}/${oci_containerengine_cluster.k8s_cluster.name}_kubeconfig"
}
