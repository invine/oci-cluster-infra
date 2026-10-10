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
    ], var.nginx_ingress_snippets_enabled ? [yamlencode({
      controller = {
        enableSnippets = true
      }
      })] : [], var.nginx_proxy_protocol_enabled ? [yamlencode({
      controller = {
        service = {
          externalTrafficPolicy = "Local"
          annotations = {
            "service.beta.kubernetes.io/oci-load-balancer-connection-proxy-protocol-version" = "2"
          }
        }
        config = {
          entries = {
            "proxy-protocol"    = "true"
            "real-ip-header"    = "proxy_protocol"
            "set-real-ip-from"  = join(",", var.nginx_lb_trusted_cidrs)
            "real-ip-recursive" = "false"
          }
        }
      }
  })] : [])

  lifecycle {
    precondition {
      condition     = !var.nginx_ingress_snippets_enabled || var.nginx_ingress_version == "2.6.4"
      error_message = "Echo client identity snippets require the qualified F5 chart 2.6.4."
    }

    precondition {
      condition     = !var.nginx_proxy_protocol_enabled || (var.nginx_ingress_version == "2.6.4" && var.nginx_ingress_snippets_enabled && length(var.nginx_lb_trusted_cidrs) > 0)
      error_message = "Client identity requires F5 chart 2.6.4, enabled snippets and explicit LB source CIDRs. Follow docs/runbooks/echo-client-identity.md."
    }
  }
}

data "kubernetes_service" "nginx_ingress_controller" {
  metadata {
    name      = "nginx-ingress-controller"
    namespace = helm_release.nginx_ingress.namespace
  }
}
