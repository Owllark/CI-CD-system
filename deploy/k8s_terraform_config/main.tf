terraform {

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
    }
  }
}

provider "vault" {
  address = "${var.vault_address}"
  token   = "${var.vault_token}"
}

resource "digitalocean_kubernetes_cluster" "kubernetes_cluster" {
  name    = var.k8s_clustername
  region  = var.region
  version = var.k8s_version

  tags = ["k8s"]

  node_pool {
    name       = var.k8s_poolname
    size       = "s-2vcpu-2gb"
    auto_scale = false
    node_count = var.k8s_node_count
  }

}

output "cluster-id" {
  value = digitalocean_kubernetes_cluster.kubernetes_cluster.id
}