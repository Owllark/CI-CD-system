#!/bin/bash

handle_error() {
  echo "Error occurred in command: $1"
  
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

if [ ! -d "secrets" ]; then
     echo "Error: directory secrets/ not found"
     exit 1
fi

kubectl create secret generic -n staging dockerhub-secret\
     --dry-run=client -o yaml \
     --from-file=.dockerconfigjson=secrets/docker_config.json \
     --type=kubernetes.io/dockerconfigjson \
      | kubectl apply -f -

kubectl create secret generic -n production dockerhub-secret\
     --dry-run=client -o yaml \
     --from-file=.dockerconfigjson=secrets/docker_config.json \
     --type=kubernetes.io/dockerconfigjson \
      | kubectl apply -f -

kubectl create secret generic -n jenkins dockerhub-secret\
     --dry-run=client -o yaml \
     --from-file=.dockerconfigjson=secrets/docker_config.json \
     --type=kubernetes.io/dockerconfigjson \
      | kubectl apply -f -

kubectl create secret generic -n argocd dockerhub-secret\
     --dry-run=client -o yaml \
     --from-file=.dockerconfigjson=secrets/docker_config.json \
     --type=kubernetes.io/dockerconfigjson \
      | kubectl apply -f -

cp -f config.json ../jenkins/
cp -f config.json ../elk/
cp -f config.json ../argocd/
echo "config.json copied to necessary directories"

cp -f utils.sh ../jenkins/
cp -f utils.sh ../elk/
cp -f utils.sh ../argocd/
echo "utils.sh copied to necessary directories"

cd secrets

[ -e "argocd_webhook_token" ] && cp -f argocd_webhook_token ../../argocd/secrets
[ -e "dockerhub_password" ]   && cp -f dockerhub_password ../../jenkins/secrets
[ -e "github_host_key" ]      && cp -f github_host_key ../../jenkins/secrets
[ -e "github_ssh" ]           && cp -f github_ssh ../../jenkins/secrets
[ -e "github_ssh" ]           && cp -f github_ssh ../../argocd/secrets
[ -e "do_token.auto.tfvars" ] && cp -f do_token.auto.tfvars ../../terraform/config
echo "Provided secrets copied to corresponding directories"


echo "Preinstall completed successfully!"

