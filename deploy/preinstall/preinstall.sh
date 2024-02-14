#!/bin/bash

helm repo add jetstack https://charts.jetstack.io --force-update
helm repo update

helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.3 \
  --set installCRDs=true


kubectl create namespace staging
kubectl create namespace production
kubectl create namespace jenkins
kubectl create namespace logging
kubectl create namespace argocd


kubectl create -n jenkins -f cluster-issuer-lets-encrypt.yaml
kubectl create -n argocd -f cluster-issuer-lets-encrypt.yaml
kubectl create -n logging -f cluster-issuer-lets-encrypt.yaml

kubectl create secret generic -n staging dockerhub-secret\
     --from-file=.dockerconfigjson=config.json\
     --type=kubernetes.io/dockerconfigjson

kubectl create secret generic -n production dockerhub-secret\
     --from-file=.dockerconfigjson=config.json\
     --type=kubernetes.io/dockerconfigjson

kubectl create secret generic -n jenkins dockerhub-secret\
     --from-file=.dockerconfigjson=config.json\
     --type=kubernetes.io/dockerconfigjson

kubectl create secret generic -n argocd dockerhub-secret\
     --from-file=.dockerconfigjson=config.json\
     --type=kubernetes.io/dockerconfigjson


