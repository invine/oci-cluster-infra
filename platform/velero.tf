# Data source to fetch the Kubernetes auth token
resource "oci_identity_customer_secret_key" "velero_access_key" {
  display_name = "velero_access_key"
  user_id      = var.user_ocid
}

resource "kubernetes_namespace" "velero" {
  metadata {
    name = "velero"
  }
}

# Helm chart to install Velero
resource "helm_release" "velero" {
  name       = "velero"
  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart      = "velero"
  version    = var.velero_version
  namespace  = kubernetes_namespace.velero.metadata[0].name

  values = [
    <<EOF
image:
  repository: docker.io/velero/velero

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
upgradeCRDs: false

credentials:
  secretContents:
    cloud: |
      [default]
      aws_access_key_id = ${oci_identity_customer_secret_key.velero_access_key.id}
      aws_secret_access_key = ${oci_identity_customer_secret_key.velero_access_key.key}
    EOF
  ]
  depends_on = [kubernetes_secret.velero_repo_credentials]
}

resource "kubernetes_secret" "velero_repo_credentials" {
  metadata {
    name      = "velero-repo-credentials"
    namespace = kubernetes_namespace.velero.metadata[0].name
  }

  data = {
    repository-password = var.velero_repository_password
  }

  type = "Opaque"

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubectl_manifest" "velero_fs_restore_action_config" {
  yaml_body = <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: fs-restore-action-config
  namespace: ${kubernetes_namespace.velero.metadata[0].name}
  labels:
    velero.io/plugin-config: ""
    velero.io/pod-volume-restore: RestoreItemAction
data:
  image: ${var.velero_restore_helper_image}
EOF

  depends_on = [helm_release.velero]
}

resource "kubectl_manifest" "velero_change_image_name_config" {
  yaml_body = <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: change-image-name-config
  namespace: ${kubernetes_namespace.velero.metadata[0].name}
  labels:
    velero.io/plugin-config: ""
    velero.io/change-image-name: RestoreItemAction
data:
  restore-helper-image: ${var.velero_restore_image_mappings["restore_helper"]}
  openvpn-image: ${var.velero_restore_image_mappings["openvpn"]}
  vaultwarden-image: ${var.velero_restore_image_mappings["vaultwarden"]}
EOF

  depends_on = [helm_release.velero]
}
