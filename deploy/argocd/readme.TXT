Prerequisites:
Helm v3 installed
nginx ingress controller

Deploy steps:

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Retrieving initial admin password:
kubectl get secret argocd-initial-admin-secret -n argocd  -o jsonpath="{.data.password}" | base64 --decode

Applying ingress(accessible via argocd.owllark.mooo.com):
kubectl apply -f argocd-ingress.yaml -n argocd