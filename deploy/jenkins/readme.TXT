Prerequisites:
Helm v3 installed

Deploy steps:

helm repo add jenkins https://charts.jenkins.io
helm repo update

helm install jenkins jenkins/jenkins --namespace jenkins --create-namespace

using yaml files in jcasc_config:
helm install jenkins jenkins/jenkins -f general.yaml -f credentials.yaml -f jobs.yaml

Retrieving admin password:
kubectl get secret jenkins -n jenkins -o jsonpath='{.data.jenkins-admin-password}' | base64 --decode

Deploying ingress-nginx as ingress controller:
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install quickstart ingress-nginx/ingress-nginx

Deploying Let's encrypt issuers:
staging - kubectl create -n jenkins --edit -f  https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/staging-issuer.yaml
prod - kubectl create -n jenkins --edit -f  https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/production-issuer.yaml

Applying ingress(accessible via jenkins.owllark.mooo.com):
kubectl apply -f jenkins-ingress.yaml -n jenkins

Applying pvc-s for agent pods use:
kubectl apply -f pvc-cypress.yaml -n jenkins
kubectl apply -f pvc-unittest.yaml -n jenkins

with secret files from jcascc_config/secrets:
kubectl create secret generic jenkins-credentials-secret ^
--from-file=argocd-webhook-token=argocd_webhook_token ^
--from-file=dockerhub-password=dockerhub_password ^
--from-file=github-host-key=github_host_key ^
--from-file=github-ssh=github_ssh ^
--from-file=github-token=github_token