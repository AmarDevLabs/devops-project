resource "kubernetes_namespace_v1" "loki" {
  metadata {
    name = var.loki_namespace
  }
}

resource "helm_release" "loki" {
  name       = "loki"
  namespace  = kubernetes_namespace_v1.loki.metadata[0].name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  timeout    = 240
  wait       = true

  values = [
    <<EOF
deploymentMode: SingleBinary

loki:
  auth_enabled: false
  commonConfig:
    replication_factor: 1
  storage:
    type: filesystem
  schemaConfig:
    configs:
      - from: "2024-04-01"
        store: tsdb
        object_store: filesystem
        schema: v13
        index:
          prefix: loki_index_
          period: 24h

singleBinary:
  replicas: 1
  persistence:
    enabled: true
    storageClass: local-path
    size: 10Gi
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      memory: 512Mi

backend:
  replicas: 0

read:
  replicas: 0

write:
  replicas: 0

chunksCache:
  enabled: false

resultsCache:
  enabled: false

minio:
  enabled: false
EOF
  ]

  depends_on = [
    kubernetes_manifest.local_path_deployment,
    kubernetes_manifest.local_path_storage_class
  ]
}
