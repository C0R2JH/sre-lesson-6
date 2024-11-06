provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

resource "kubernetes_namespace" "tf-k8s-ns" {
  metadata {
    name = "eak-ns"
  }
}

resource "kubernetes_deployment" "tf-k8s-deployment" {
  metadata {
    name = "eak-deployment"
    labels = {
      test = "eak-app"
    }
    namespace = kubernetes_namespace.tf-k8s-ns.id
  }
  spec {
    replicas = 3

    selector {
      match_labels = {
        test = "eak-app"
      }
    }

    template {
      metadata {
        labels = {
          test = "eak-app"
        }
      }

      spec {
        container {
          image = "nginx:1.21.6"
          name  = "demo"

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }

          }
        }
      }
    }
  }
}

resource "kubernetes_service" "tf-k8s-service-nginx" {
  metadata {
    name      = "eak-service-nginx"
    namespace = kubernetes_namespace.tf-k8s-ns.id
  }
  spec {
    selector = {
      App = kubernetes_deployment.tf-k8s-deployment.spec.0.template.0.metadata[0].labels.test
    }
    port {
      node_port   = 30201
      port        = 80
      target_port = 80
    }

    type = "NodePort"
  }
}

resource "kubernetes_network_policy" "eak-tf-k8s-network" {
  metadata {
    name      = "eak-tf-k8s-network"
    namespace = kubernetes_namespace.tf-k8s-ns.id
  }

  spec {
    pod_selector {
      match_labels = {
        test = "eak-app"
      }
    }

    ingress {
      ports {
        port     = "10080"
        protocol = "TCP"
      }
      ports {
        port     = "10443"
        protocol = "TCP"
      }

      from {
        namespace_selector {
          match_labels = {
            test = "eak-app"
          }
        }
      }

      from {
        ip_block {
          cidr = "10.0.0.0/8"
          except = [
            "10.0.0.0/24",
            "10.0.1.0/24",
          ]
        }
      }
    }

    egress {}

    policy_types = ["Ingress", "Egress"]
  }
}
