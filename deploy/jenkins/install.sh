#!/bin/bash

source ./utils.sh

handle_error() {
  echo "Error occurred in command: $1"
  
  exit 1
}

JENKINS_USERNAME="admin"
JENKINS_PASSWORD=""

trap 'handle_error $BASH_COMMAND' ERR

kubectl create namespace jenkins --dry-run=client -o yaml | kubectl apply -f -

kubectl config set-context --current --namespace=jenkins

helm repo add jenkins https://charts.jenkins.io
helm repo update

cd secrets

kubectl create secret generic jenkins-credentials-secret \
--dry-run=client -o yaml \
--from-file=argocd-webhook-token=argocd_webhook_token \
--from-file=dockerhub-password=dockerhub_password \
--from-file=github-host-key=github_host_key \
--from-file=github-ssh=github_ssh \
 | kubectl apply -f -


cd ../values

files=("general.yaml" "credentials.yaml" "groovy-scripts.yaml" "ingress.yaml" "jobs.yaml")
DIR_RENDERED="_rendered_"
declare -A params
utils_parse_json params ../config.json
utils_substitute_placeholders params $DIR_RENDERED "${files[@]}"

helm upgrade --install jenkins jenkins/jenkins \
    -f $DIR_RENDERED/general.yaml \
    -f $DIR_RENDERED/credentials.yaml \
    -f $DIR_RENDERED/groovy-scripts.yaml \
    -f $DIR_RENDERED/ingress.yaml \
    -f $DIR_RENDERED/jobs.yaml

                                    
utils_delete_rendered_files $DIR_RENDERED "${files[@]}"

cd ..

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=jenkins --timeout=-1s


JENKINS_PASSWORD=$(kubectl exec -n jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password)


echo "$JENKINS_USERNAME $JENKINS_PASSWORD" > jenkins_credentials

echo "credentials: " $JENKINS_USERNAME $JENKINS_PASSWORD

echo "Jenkins installed successfully!"






