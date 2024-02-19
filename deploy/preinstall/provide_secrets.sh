#!/bin/bash

handle_error() {
  echo "Error occurred in command: $1"
  
  exit 1
}

trap 'handle_error $BASH_COMMAND' ERR

if [ ! -d "secrets" ]; then
     echo "Error: directory secrets/ not found"
     exit 1
fi

cd secrets

kubectl create secret generic -n staging dockerhub-secret\
     --dry-run=client -o yaml \
     --from-file=.dockerconfigjson=docker_config.json \
     --type=kubernetes.io/dockerconfigjson \
      | kubectl apply -f -

kubectl create secret generic -n production dockerhub-secret\
     --dry-run=client -o yaml \
     --from-file=.dockerconfigjson=docker_config.json \
     --type=kubernetes.io/dockerconfigjson \
      | kubectl apply -f -

kubectl create secret generic -n jenkins dockerhub-secret\
     --dry-run=client -o yaml \
     --from-file=.dockerconfigjson=docker_config.json \
     --type=kubernetes.io/dockerconfigjson \
      | kubectl apply -f -

kubectl create secret generic -n argocd dockerhub-secret\
     --dry-run=client -o yaml \
     --from-file=.dockerconfigjson=docker_config.json \
     --type=kubernetes.io/dockerconfigjson \
      | kubectl apply -f -

[ -e "argocd_webhook_token" ] && cp -f argocd_webhook_token ../../argocd/secrets
[ -e "dockerhub_password" ]   && cp -f dockerhub_password ../../jenkins/secrets
[ -e "github_host_key" ]      && cp -f github_host_key ../../jenkins/secrets
[ -e "github_ssh" ]           && cp -f github_ssh ../../jenkins/secrets
[ -e "github_ssh" ]           && cp -f github_ssh ../../argocd/secrets

echo "Provided secrets copied to corresponding directories!"
