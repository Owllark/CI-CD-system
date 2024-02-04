helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-controller ingress-nginx/ingress-nginx -namespace ingress-controller --create-namespace