resource "kubernetes_namespace" "longhorn" {
  metadata {
    name = "longhorn-system"
  }
}

locals {
  # v1.10.2's official release notes require the hotfixed backing image manager.
  longhorn_backing_image_manager_tag = var.longhorn_version == "1.10.2" ? "v1.10.2-hotfix-1" : "v${var.longhorn_version}"

  # Charts before v1.10 expect the registry in each repository. Newer charts
  # prepend their default docker.io registry and would otherwise render it twice.
  longhorn_image_repository_prefix = contains([
    "1.7.2",
    "1.8.2",
    "1.9.2",
  ], var.longhorn_version) ? "docker.io/longhornio" : "longhornio"
}

resource "helm_release" "longhorn" {
  name       = "longhorn"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  version    = var.longhorn_version
  namespace  = kubernetes_namespace.longhorn.metadata[0].name

  values = concat([
    <<EOF
image:
  longhorn:
    backingImageManager:
      repository: ${local.longhorn_image_repository_prefix}/backing-image-manager
    engine:
      repository: ${local.longhorn_image_repository_prefix}/longhorn-engine
    instanceManager:
      repository: ${local.longhorn_image_repository_prefix}/longhorn-instance-manager
    manager:
      repository: ${local.longhorn_image_repository_prefix}/longhorn-manager
    shareManager:
      repository: ${local.longhorn_image_repository_prefix}/longhorn-share-manager
    supportBundleKit:
      repository: ${local.longhorn_image_repository_prefix}/support-bundle-kit
    ui:
      repository: ${local.longhorn_image_repository_prefix}/longhorn-ui
  csi:
    attacher:
      repository: ${local.longhorn_image_repository_prefix}/csi-attacher
    livenessProbe:
      repository: ${local.longhorn_image_repository_prefix}/livenessprobe
    nodeDriverRegistrar:
      repository: ${local.longhorn_image_repository_prefix}/csi-node-driver-registrar
    provisioner:
      repository: ${local.longhorn_image_repository_prefix}/csi-provisioner
    resizer:
      repository: ${local.longhorn_image_repository_prefix}/csi-resizer
    snapshotter:
      repository: ${local.longhorn_image_repository_prefix}/csi-snapshotter

defaultSettings:
  defaultReplicaCount: 3
  allowVolumeCreationWithDegradedAvailability: false
  replicaSoftAntiAffinity: false
  replicaAutoBalance: best-effort

persistence:
  defaultClass: true
  defaultClassReplicaCount: 3
  defaultDataLocality: disabled
EOF
    ], var.longhorn_version == "1.7.2" ? [] : [
    <<EOF
preUpgradeChecker:
  jobEnabled: true
  upgradeVersionCheck: true

image:
  longhorn:
    backingImageManager:
      tag: ${local.longhorn_backing_image_manager_tag}

defaultSettings:
  concurrentAutomaticEngineUpgradePerNodeLimit: 0
  v2DataEngine: false

persistence:
  dataEngine: v1
EOF
  ])
}
