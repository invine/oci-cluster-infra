resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    name = "nginx-ingress"
  }
}

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  namespace  = kubernetes_namespace.nginx_ingress.metadata[0].name
  repository = "https://helm.nginx.com/stable"
  chart      = "nginx-ingress"
  version    = var.nginx_ingress_version

  values = concat([
    <<EOF
  controller:
    image:
      repository: docker.io/nginx/nginx-ingress
    kind: daemonset
    service:
      type: LoadBalancer
      annotations:
        service.beta.kubernetes.io/oci-load-balancer-shape: "flexible"
        service.beta.kubernetes.io/oci-load-balancer-shape-flex-min: "10"
        service.beta.kubernetes.io/oci-load-balancer-shape-flex-max: "10"
        oci.oraclecloud.com/security-rule-management-mode: "None"
    livenessProbe:
      httpGet:
        path: /healthz
        port: 10254
    readinessProbe:
      httpGet:
        path: /healthz
        port: 10254
    extraArgs:
      health-check-path: /healthz
  EOF
    ], var.nginx_ingress_version == "1.4.0" ? [] : [
    <<EOF
  # Pin the chart 1.4.0 identities across the 3.x-to-4.x migration. Changing
  # them can replace the OCI Load Balancer-backed Service or its selectors.
  serviceNameOverride: nginx-ingress-controller
  controller:
    name: controller
    selectorLabels:
      app.kubernetes.io/name: nginx-ingress
      app.kubernetes.io/instance: nginx-ingress
    logLevel: ${startswith(var.nginx_ingress_version, "1.") ? 1 : "info"}
    logFormat: glog
  EOF
  ])
}

data "kubernetes_service" "nginx_ingress_controller" {
  metadata {
    name      = "nginx-ingress-controller"
    namespace = helm_release.nginx_ingress.namespace
  }
}
