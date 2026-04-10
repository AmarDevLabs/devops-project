resource "kubernetes_namespace" "grafana" {
  metadata {
    name = var.grafana_namespace
  }
}

resource "helm_release" "grafana" {
  name      = "grafana"
  namespace = kubernetes_namespace.grafana.metadata[0].name

  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"

  values = [
    <<EOF
adminPassword: admin123

service:
  type: NodePort

persistence:
  enabled: true
  size: 5Gi
EOF
  ]
}
