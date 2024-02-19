#!/bin/bash

source ./utils.sh

handle_error() {
  echo "Error occurred in command: $1"
  
  exit 1
}

trap 'handle_error $BASH_COMMAND' ERR

if [ ! -e "config.json" ]; then
     echo "Error: config.json not found"
     exit 1
fi

files=("values.yaml" "notifications-cm.yaml" "argocd-application.yaml" "argocd-application-staging.yaml")

DIR_RENDERED="_rendered_"

declare -A params
utils_parse_json params config.json
utils_substitute_placeholders params $DIR_RENDERED "${files[@]}"

ARGOCD_PASSWORD=""
ARGOCD_USERNAME="admin"
REPO_URL="${params[repoUrlSSH]}"
REPO_PRIVATE_KEY_FILE="secrets/github_ssh"

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl config set-context --current --namespace=argocd

helm repo add argocd https://argoproj.github.io/argo-helm
helm repo update

helm upgrade --install argocd argocd/argo-cd -f $DIR_RENDERED/values.yaml

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-application-controller --timeout=-1s

ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret  -o jsonpath="{.data.password}" | base64 --decode)

echo "credentials: " $ARGOCD_USERNAME $ARGOCD_PASSWORD
echo $ARGOCD_USERNAME $ARGOCD_PASSWORD > argocd-credentials

ARGOCD_POD_NAME="argocd-application-controller-0"
ARGOCD_URL="http://argocd-server.argocd.svc"

REMOTE_DIR="/home/argocd"
KEY_FILENAME="github.ssh"
kubectl cp "$REPO_PRIVATE_KEY_FILE" "$ARGOCD_POD_NAME:$REMOTE_DIR/$KEY_FILENAME"


kubectl exec -it "$ARGOCD_POD_NAME" -- /bin/sh -c "
  argocd login $ARGOCD_URL --core --username $ARGOCD_USERNAME --password $ARGOCD_PASSWORD --insecure
  argocd repo add $REPO_URL --insecure-ignore-host-key --ssh-private-key-path $REMOTE_DIR/$KEY_FILENAME
"

kubectl delete secret argocd-notifications-secret 
kubectl create secret generic argocd-notifications-secret \
  --from-file=jenkins-token=secrets/argocd_webhook_token

kubectl delete configmap argocd-notifications-cm
kubectl create -f $DIR_RENDERED/notifications-cm.yaml

kubectl apply -f $DIR_RENDERED/argocd-application.yaml
kubectl apply -f $DIR_RENDERED/argocd-application-staging.yaml

echo "ArgoCD installed successfully!"
