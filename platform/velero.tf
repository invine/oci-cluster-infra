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

locals {
  # Keep every component on the release set frozen in the production upgrade
  # plan. Selecting the chart is the only version input; the remaining images
  # cannot drift to a different Velero minor independently.
  velero_release_sets = {
    "7.2.2" = {
      application_version = "1.14.1"
      aws_plugin_version  = "1.8.2"
    }
    "8.7.2" = {
      application_version = "1.15.2"
      aws_plugin_version  = "1.11.1"
    }
    "10.1.3" = {
      application_version = "1.16.2"
      aws_plugin_version  = "1.12.2"
    }
    "11.4.0" = {
      application_version = "1.17.1"
      aws_plugin_version  = "1.13.2"
    }
    "12.1.0" = {
      application_version = "1.18.1"
      aws_plugin_version  = "1.14.2"
    }
  }

  velero_release              = local.velero_release_sets[var.velero_version]
  velero_aws_plugin_image     = "docker.io/velero/velero-plugin-for-aws:v${local.velero_release.aws_plugin_version}"
  velero_restore_helper_image = "docker.io/velero/velero-restore-helper:v${local.velero_release.application_version}"
}

# Helm chart to install Velero
resource "helm_release" "velero" {
  name       = "velero"
  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart      = "velero"
  version    = var.velero_version
  namespace  = kubernetes_namespace.velero.metadata[0].name

  values = concat([
    <<EOF
image:
  repository: docker.io/velero/velero

initContainers:
- name: "velero-plugin-for-aws"
  image: "${local.velero_aws_plugin_image}"
  imagePullPolicy: "IfNotPresent"
  volumeMounts:
  - mountPath: /target
    name: plugins

configuration:
  # AWS SDKs released after December 2024 add CRC checksums to S3 uploads by
  # default, even when the plugin-level checksum algorithm below is empty.
  # OCI Object Storage rejects that AWS chunked encoding, so restrict SDK
  # checksums to operations where the S3 API actually requires one.
  extraEnvVars:
    - name: AWS_REQUEST_CHECKSUM_CALCULATION
      value: WHEN_REQUIRED
  backupStorageLocation:
    - name: "default"
      provider: "aws"
      bucket: "${var.velero_backup_bucket_name}"
      prefix: "${var.velero_backup_bucket_prefix}"
      config:
        region: "${var.region}"
        s3Url: "https://${var.velero_backup_bucket_namespace}.compat.objectstorage.${var.region}.oraclecloud.com"
        s3ForcePathStyle: "true"
        checksumAlgorithm: ""

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
    ], var.velero_version == "7.2.2" ? [] : [
    <<EOF
image:
  tag: "v${local.velero_release.application_version}"
EOF
  ])
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
  image: ${local.velero_restore_helper_image}
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
