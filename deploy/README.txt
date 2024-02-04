Directory contains Makefile that starts automatic cluster configuration

Prerequisites:
Helm v3 installed
kubectl installed

To obtain tls certificates, before starting the automatic configuration, 
you need to bind the domain names used in ingresses to the load balancer, 
so nginx ingress-controller must be installed in the cluster. 
You can also use "make install-ingress-controller" for this

Secrets are not stored in the repository so you must add them yourself, namely:
argocd/github_ssh_private - private ssh key for github authorization
argocd/argocd_webhook_token - token used to authenticate argocd webhook

jenkins/values/secrets/dockerhub_password - dockerhub token for pushing images from jenkins build argocd_webhook_token
jenkins/values/secrets/github_host_key - github host key for host verification
jenkins/values/secrets/github_ssh - private ssh key for github authorization 
jenkins/values/secrets/argocd_webhook_token - token used to authenticate argocd webhook

preinstall/config.json - file that holds the Dockerhub authorization token 

To start automatic installation run:
make install
