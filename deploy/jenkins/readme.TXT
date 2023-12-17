Prerequisites:
Helm v3 installed

Deploy steps:

helm repo add jenkins https://charts.jenkins.io
helm repo update

helm install jenkins jenkins/jenkins --namespace jenkins --create-namespace

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