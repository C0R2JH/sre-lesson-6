provider "kubernetes" {
  config_path    = "kube/config"
  config_context = "minikube"
}

resource "kubernetes_namespace" "eak_k8s_ns" {
  metadata {
    name = "eak_k8s_ns_tf"
  }
}
