resource "kubernetes_namespace_v1" "grafana" {
  metadata {
    name = var.grafana_namespace
  }
}


resource "helm_release" "grafana" {
  name            = "grafana"
  namespace       = kubernetes_namespace_v1.grafana.metadata[0].name
  repository      = "https://grafana.github.io/helm-charts"
  chart           = "grafana"
  timeout         = 240
  wait            = true
  atomic          = true
  cleanup_on_fail = true

  values = [
    <<EOF
adminPassword: admin123

service:
  type: NodePort

persistence:
  enabled: true
  storageClassName: local-path
  size: 5Gi

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    memory: 256Mi
EOF
  ]

   depends_on = [
    kubernetes_manifest.local_path_deployment,
    kubernetes_manifest.local_path_storage_class
  ]
}

