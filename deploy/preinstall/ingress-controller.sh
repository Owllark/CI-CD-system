helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm upgrade --install ingress-controller ingress-nginx/ingress-nginx --namespace ingress-controller --create-namespace
kubectl wait --namespace ingress-controller --for=condition=available deployment/ingress-controller-ingress-nginx-controller --timeout=300s

LB_IP=$(kubectl get service ingress-controller-ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' --namespace ingress-controller)

echo "Load Balancer IP: $LB_IP"