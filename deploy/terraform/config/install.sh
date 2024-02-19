#!/bin/bash

handle_error() {
  echo "Error occurred in command: $1"
  
  exit 1
}

trap 'handle_error $BASH_COMMAND' ERR

terraform init 

terraform apply -auto-approve

terraform output -raw kubeconfig > kubeconfig.yaml

current_context=$(kubectl config current-context --kubeconfig kubeconfig.yaml)

export KUBECONFIG=~/.kube/config:kubeconfig.yaml

kubectl config view --flatten > merged-kubeconfig.yaml

cp merged-kubeconfig.yaml ~/.kube/config

export KUBECONFIG=~/.kube/config

kubectl config use-context $current_context

echo "Terraform configuration applied succeffully!"

