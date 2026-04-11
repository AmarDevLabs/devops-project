resource "kubernetes_namespace_v1" "local_path_storage" {
  metadata {
    name = "local-path-storage"
  }
}

resource "kubernetes_manifest" "local_path_service_account" {
  manifest = {
    apiVersion = "v1"
    kind       = "ServiceAccount"
    metadata = {
      name      = "local-path-provisioner-service-account"
      namespace = kubernetes_namespace_v1.local_path_storage.metadata[0].name
    }
  }
}

resource "kubernetes_manifest" "local_path_cluster_role" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRole"
    metadata = {
      name = "local-path-provisioner-role"
    }
    rules = [
      {
        apiGroups = [""]
        resources = ["nodes", "persistentvolumeclaims", "configmaps", "pods", "pods/log"]
        verbs     = ["get", "list", "watch", "create", "delete"]
      },
      {
        apiGroups = [""]
        resources = ["persistentvolumes"]
        verbs     = ["get", "list", "watch", "create", "patch", "delete"]
      },
      {
        apiGroups = ["storage.k8s.io"]
        resources = ["storageclasses"]
        verbs     = ["get", "list", "watch"]
      },
      {
        apiGroups = [""]
        resources = ["events"]
        verbs     = ["create", "patch"]
      }
    ]
  }
}

resource "kubernetes_manifest" "local_path_cluster_role_binding" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"
    metadata = {
      name = "local-path-provisioner-bind"
    }
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "ClusterRole"
      name     = "local-path-provisioner-role"
    }
    subjects = [
      {
        kind      = "ServiceAccount"
        name      = "local-path-provisioner-service-account"
        namespace = kubernetes_namespace_v1.local_path_storage.metadata[0].name
      }
    ]
  }

  depends_on = [
    kubernetes_manifest.local_path_cluster_role,
    kubernetes_manifest.local_path_service_account
  ]
}

resource "kubernetes_manifest" "local_path_configmap" {
  manifest = {
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "local-path-config"
      namespace = kubernetes_namespace_v1.local_path_storage.metadata[0].name
    }
    data = {
      "config.json" = jsonencode({
        nodePathMap = [
          {
            node  = "DEFAULT_PATH_FOR_NON_LISTED_NODES"
            paths = ["/opt/local-path-provisioner"]
          }
        ]
      })
      "helperPod.yaml" = <<-EOT
apiVersion: v1
kind: Pod
metadata:
  name: helper-pod
spec:
  priorityClassName: system-node-critical
  tolerations:
    - key: node.kubernetes.io/disk-pressure
      operator: Exists
      effect: NoSchedule
  containers:
    - name: helper-pod
      image: busybox
      imagePullPolicy: IfNotPresent
      command: ["/bin/sh", "-c", "sleep 3600"]
  restartPolicy: Never
      EOT
      "setup"          = <<-EOT
#!/bin/sh
set -eu
mkdir -p "$VOL_DIR"
chmod 0777 "$VOL_DIR"
      EOT
      "teardown"       = <<-EOT
#!/bin/sh
set -eu
rm -rf "$VOL_DIR"
      EOT
    }
  }

  depends_on = [kubernetes_namespace_v1.local_path_storage]
}

resource "kubernetes_manifest" "local_path_storage_class" {
  manifest = {
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      name = "local-path"
      annotations = {
        "storageclass.kubernetes.io/is-default-class" = "true"
      }
    }
    provisioner          = "rancher.io/local-path"
    reclaimPolicy        = "Delete"
    volumeBindingMode    = "WaitForFirstConsumer"
    allowVolumeExpansion = true
  }
}

resource "kubernetes_manifest" "local_path_deployment" {
  manifest = {
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata = {
      name      = "local-path-provisioner"
      namespace = kubernetes_namespace_v1.local_path_storage.metadata[0].name
    }
    spec = {
      replicas = 1
      selector = {
        matchLabels = {
          app = "local-path-provisioner"
        }
      }
      template = {
        metadata = {
          labels = {
            app = "local-path-provisioner"
          }
        }
        spec = {
          serviceAccountName = "local-path-provisioner-service-account"
          containers = [
            {
              name            = "local-path-provisioner"
              image           = "rancher/local-path-provisioner:v0.0.32"
              imagePullPolicy = "IfNotPresent"
              command = [
                "local-path-provisioner",
                "--debug",
                "start",
                "--config",
                "/etc/config/config.json"
              ]
              volumeMounts = [
                {
                  name      = "config-volume"
                  mountPath = "/etc/config/"
                }
              ]
            }
          ]
          volumes = [
            {
              name = "config-volume"
              configMap = {
                name = "local-path-config"
              }
            }
          ]
        }
      }
    }
  }

  depends_on = [
    kubernetes_manifest.local_path_cluster_role_binding,
    kubernetes_manifest.local_path_configmap,
    kubernetes_manifest.local_path_storage_class
  ]
}
