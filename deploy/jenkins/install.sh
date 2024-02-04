#!/bin/bash

JENKINS_URL="http://jenkins.owllark.chickenkiller.com"

JENKINS_USERNAME="admin"
JENKINS_PASSWORD=""



kubectl create namespace jenkins

kubectl config set-context --current --namespace=jenkins

helm repo add jenkins https://charts.jenkins.io
helm repo update

cd values/secrets

kubectl create secret generic jenkins-credentials-secret \
--from-file=argocd-webhook-token=argocd_webhook_token \
--from-file=dockerhub-password=dockerhub_password \
--from-file=github-host-key=github_host_key \
--from-file=github-ssh=github_ssh \
--from-file=github-token=github_token

cd ..

helm install jenkins jenkins/jenkins -f general.yaml -f credentials.yaml -f jobs.yaml -f groovy-scripts.yaml -f ingress.yaml
cd ..

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=jenkins --timeout=-1s

JENKINS_PASSWORD=$(kubectl exec -n jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password)


echo "$JENKINS_USERNAME $JENKINS_PASSWORD" > jenkins_credentials

echo $JENKINS_URL
echo "credentials: " $JENKINS_PASSWORD $JENKINS_PASSWORD

kubectl apply -f pvc-cypress.yaml
kubectl apply -f pvc-unittest.yaml






