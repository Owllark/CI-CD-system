terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "do_token" {
}

variable "instance_count" {
  default = "1"
}

variable "do_snapshot_id" {
}

variable "do_name" {
  default = "vault"
}

variable "do_region" {
}

variable "do_size" {
}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "vault" {
  name = "vault"
}