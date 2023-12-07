variable "vault_address" {
}

variable "vault_token" {

}

variable "region" {
  default = "nyc3"
}

variable "k8s_clustername" {
  default = "k8s-cluster"
}

variable "k8s_version" {
  default = "1.28.2-do.0"
}

variable "k8s_poolname" {
  default = "worker-pool"
}

variable "k8s_node_count" {
  default = "3"
}