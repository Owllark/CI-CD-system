#!/bin/bash

handle_error() {
  echo "Error occurred in command: $1"
  helm ls --all-namespaces
  exit 1
}

trap 'handle_error $BASH_COMMAND' ERR

helm repo add jetstack https://charts.jetstack.io --force-update
helm repo update

helm upgrade --install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.3 \
  --set installCRDs=true


kubectl create namespace staging    --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace jenkins    --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace logging    --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace argocd     --dry-run=client -o yaml | kubectl apply -f -

kubectl create -n jenkins -f issuer-lets-encrypt.yaml --dry-run=client -o yaml | kubectl apply -f -
kubectl create -n argocd  -f issuer-lets-encrypt.yaml --dry-run=client -o yaml | kubectl apply -f -
kubectl create -n logging -f issuer-lets-encrypt.yaml --dry-run=client -o yaml | kubectl apply -f -

echo "Preinstall actions completed successfully!"