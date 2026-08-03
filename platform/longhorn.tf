resource "kubernetes_namespace" "longhorn" {
  metadata {
    name = "longhorn-system"
  }
}

resource "helm_release" "longhorn" {
  name       = "longhorn"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  version    = var.longhorn_version
  namespace  = kubernetes_namespace.longhorn.metadata[0].name

  values = [
    <<EOF
image:
  longhorn:
    backingImageManager:
      repository: docker.io/longhornio/backing-image-manager
    engine:
      repository: docker.io/longhornio/longhorn-engine
    instanceManager:
      repository: docker.io/longhornio/longhorn-instance-manager
    manager:
      repository: docker.io/longhornio/longhorn-manager
    shareManager:
      repository: docker.io/longhornio/longhorn-share-manager
    supportBundleKit:
      repository: docker.io/longhornio/support-bundle-kit
    ui:
      repository: docker.io/longhornio/longhorn-ui
  csi:
    attacher:
      repository: docker.io/longhornio/csi-attacher
    livenessProbe:
      repository: docker.io/longhornio/livenessprobe
    nodeDriverRegistrar:
      repository: docker.io/longhornio/csi-node-driver-registrar
    provisioner:
      repository: docker.io/longhornio/csi-provisioner
    resizer:
      repository: docker.io/longhornio/csi-resizer
    snapshotter:
      repository: docker.io/longhornio/csi-snapshotter

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
  ]
}
