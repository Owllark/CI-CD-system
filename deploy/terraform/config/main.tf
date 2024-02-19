terraform {

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
   token = var.do_token
}

resource "digitalocean_kubernetes_cluster" "kubernetes_cluster" {
  name    = var.k8s_clustername
  region  = var.region
  version = var.k8s_version

  tags = ["k8s"]

  node_pool {
    name       = var.k8s_poolname
    size       = "s-2vcpu-4gb"
    auto_scale = false
    node_count = var.k8s_node_count
  }

}


output "cluster-id" {
  value = digitalocean_kubernetes_cluster.kubernetes_cluster.id
}

output "cluster-context-name" {
  value = format("%s-%s", digitalocean_kubernetes_cluster.kubernetes_cluster.name, digitalocean_kubernetes_cluster.kubernetes_cluster.region)
}

output "kubeconfig" {
  value = digitalocean_kubernetes_cluster.kubernetes_cluster.kube_config.0.raw_config
  sensitive = true
}