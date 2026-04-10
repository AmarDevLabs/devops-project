resource "kubernetes_namespace" "loki" {
  metadata {
    name = var.loki_namespace
  }
}

resource "helm_release" "loki" {
  name       = "loki"
  namespace  = kubernetes_namespace.loki.metadata[0].name

  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"

  values = [
    <<EOF
loki:
  auth_enabled: false

singleBinary:
  replicas: 1

persistence:
  enabled: true
  size: 10Gi
EOF
  ]
}
