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

  values = [
    <<EOF
  controller:
    kind: daemonset
    service:
      type: LoadBalancer
      annotations:
        service.beta.kubernetes.io/oci-load-balancer-shape: "flexible"
        service.beta.kubernetes.io/oci-load-balancer-shape-flex-min: "10"
        service.beta.kubernetes.io/oci-load-balancer-shape-flex-max: "10"
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
  ]
}

data "kubernetes_service" "nginx_ingress_controller" {
  metadata {
    name      = "nginx-ingress-controller"
    namespace = helm_release.nginx_ingress.namespace
  }
}
