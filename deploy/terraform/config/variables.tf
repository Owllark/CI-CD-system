variable "do_token" {

}

variable "region" {
  default = "nyc3"
}

variable "k8s_clustername" {
  default = "k8s-cluster"
}

variable "k8s_version" {
  default = "1.29.1-do.0"
}

variable "k8s_poolname" {
  default = "worker-pool"
}

variable "k8s_node_count" {
  default = "2"
}