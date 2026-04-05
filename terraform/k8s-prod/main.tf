resource "kubernetes_namespace" "frontend" {
  metadata {
    name = var.frontend_namespace
  }
}

resource "kubernetes_namespace" "backend" {
  metadata {
    name = var.backend_namespace
  }
}

resource "kubernetes_deployment" "frontend_app" {
  metadata {
    name      = "frontend-app"
    namespace = kubernetes_namespace.frontend.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "frontend-app"
      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_unavailable = 1
        max_surge       = 1
      }
    }

    template {
      metadata {
        labels = {
          app = "frontend-app"
        }
      }

      spec {
        container {
          name  = "frontend-app"
          image = "nginx:1.29.0"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "frontend_app" {
  metadata {
    name      = "frontend-service"
    namespace = kubernetes_namespace.frontend.metadata[0].name
  }

  spec {
    selector = {
      app = "frontend-app"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_deployment" "backend_app" {
  metadata {
    name      = "backend-app"
    namespace = kubernetes_namespace.backend.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "backend-app"
      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_unavailable = 1
        max_surge       = 1
      }
    }

    template {
      metadata {
        labels = {
          app = "backend-app"
        }
      }

      spec {
        container {
          name  = "backend-app"
          image = "httpd:2.4"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "backend_app" {
  metadata {
    name      = "backend-service"
    namespace = kubernetes_namespace.backend.metadata[0].name
  }

  spec {
    selector = {
      app = "backend-app"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}
