handle_error() {
  echo "Error occurred in command: $1"
  
  exit 1
}
trap 'handle_error $BASH_COMMAND' ERR

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm upgrade --install ingress-controller ingress-nginx/ingress-nginx --namespace ingress-controller --create-namespace
kubectl wait --namespace ingress-controller --for=condition=Ready pod -l app.kubernetes.io/instance=ingress-controller --timeout=-1s

LB_IP=$(kubectl get service ingress-controller-ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' --namespace ingress-controller)

echo "Load Balancer IP: $LB_IP"