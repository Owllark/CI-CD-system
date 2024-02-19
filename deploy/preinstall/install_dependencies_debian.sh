#!/bin/bash

handle_error() {
  echo "Error occurred in command: $1"
  
  exit 1
}

trap 'handle_error $BASH_COMMAND' ERR

# Function to check if a command is available
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# helm
if ! command_exists helm; then
  echo "Installing Helm v3..."
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
  chmod +x get_helm.sh
  ./get_helm.sh
  rm get_helm.sh
  echo "Helm v3 installed successfully."
else
  echo "Helm v3 is already installed."
fi

# kubectl
if ! command_exists kubectl; then
  echo "Installing kubectl..."
  apt-get update
  apt-get install -y apt-transport-https ca-certificates curl
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
  apt-get update
  apt-get install -y kubectl
  echo "kubectl installed successfully."
else
  echo "kubectl is already installed."
fi

# terraform
if ! command_exists terraform; then
  echo "Installing Terraform..."
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

 echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

 sudo apt update && sudo apt install -y terraform
  echo "Terraform installed successfully."
else
  echo "Terraform is already installed."
fi

# jq
if ! command_exists jq; then
  echo "Installing jq..."
  apt-get update
  apt-get install -y jq
  echo "jq installed successfully."
else
  echo "jq is already installed."
fi

echo "Dependency installation completed!"