domain name for jenkins ingress - owllark.jenkins.mooo.com

For configuring https on ingress were used:

ingress-nginx as ingress controller:
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install quickstart ingress-nginx/ingress-nginx

let's encrypt issuers:
staging - https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/staging-issuer.yaml
prod - https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/production-issuer.yaml