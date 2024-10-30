# Data source to fetch the Kubernetes auth token
resource "oci_identity_customer_secret_key" "velero_access_key" {
  display_name = "velero_access_key"
  user_id      = var.user_ocid
}

resource "kubernetes_namespace" "velero" {
  metadata {
    name = "velero"
  }
  depends_on = [
    oci_containerengine_cluster.k8s_cluster,
    local_file.k8s_cluster_kube_config_file
  ]
}

# Helm chart to install Velero
resource "helm_release" "velero" {
  name       = "velero"
  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart      = "velero"
  namespace  = kubernetes_namespace.velero.metadata[0].name

  values = [
    <<EOF
initContainers:
- name: "velero-plugin-for-aws"
  image: "${var.velero_aws_plugin_image}"
  imagePullPolicy: "IfNotPresent"
  volumeMounts:
  - mountPath: /target
    name: plugins

configuration:
  backupStorageLocation:
    - name: "default"
      provider: "aws"
      bucket: "${var.velero_backup_bucket_name}"
      prefix: "${var.velero_backup_bucket_prefix}"
      config:
        region: "${var.region}"
        s3Url: "https://${var.velero_backup_bucket_namespace}.compat.objectstorage.${var.region}.oraclecloud.com"
        s3ForcePathStyle: "true"

deployNodeAgent: true
snapshotsEnabled: false

credentials:
  secretContents:
    cloud: |
      [default]
      aws_access_key_id = ${oci_identity_customer_secret_key.velero_access_key.id}
      aws_secret_access_key = ${oci_identity_customer_secret_key.velero_access_key.key}
    EOF
  ]

  depends_on = [
    kubernetes_namespace.velero
  ]
}
