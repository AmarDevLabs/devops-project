resource "helm_release" "loki" {
  name      = "loki"
  namespace = kubernetes_namespace_v1.loki.metadata[0].name

  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"

  timeout = 600

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
    size: 10Gi

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
}
