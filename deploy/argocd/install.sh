ARGOCD_PASSWORD=""
ARGOCD_USERNAME="admin"
REPO_URL="git@github.com:Owllark/igorbaran_devops_internship_practice.git"
REPO_PRIVATE_KEY_FILE="github_ssh_private"

kubectl create namespace argocd
kubectl config set-context --current --namespace=argocd

helm repo add argocd https://argoproj.github.io/argo-helm
helm repo update

kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/crds/application-crd.yaml

helm install argocd argocd/argo-cd -f values.yaml

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-application-controller --timeout=-1s

ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret  -o jsonpath="{.data.password}" | base64 --decode)

echo "credentials: " $ARGOCD_USERNAME $ARGOCD_PASSWORD

kubectl delete secret argocd-initial-admin-secret

ARGOCD_POD_NAME="argocd-application-controller-0"
ARGOCD_URL="http://argocd-server.argocd.svc"

REMOTE_DIR="/home/argocd"
kubectl cp "$REPO_PRIVATE_KEY_FILE" "$ARGOCD_POD_NAME:$REMOTE_DIR/"


kubectl exec -it "$ARGOCD_POD_NAME" -- /bin/sh -c "
  argocd login $ARGOCD_URL --core --username $ARGOCD_USERNAME --password $ARGOCD_PASSWORD --insecure
  argocd repo add $REPO_URL --insecure-ignore-host-key --ssh-private-key-path $REMOTE_DIR/$REPO_PRIVATE_KEY_FILE
"

kubectl create secret generic argocd-notifications-secret \
  --from-file=jenkins-token=argocd_webhook_token

kubectl apply -f notifications-cm.yaml
kubectl apply -f argocd-application.yaml
kubectl apply -f argocd-application-staging.yaml
