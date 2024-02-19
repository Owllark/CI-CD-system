Directory contains Makefile that starts automatic cluster configuration

Prerequisites:
Helm v3 installed
kubectl installed
terraform installed
jq installed

If you want to install dependencies automatically, for Debian system you can run "make install_dependecies_debian"

SECRETS:

Before commencing the automatic installation, you should provide necessary secrets.
You have several options for doing this:

1) Place secret files into the deploy/preinstall/secrets directory.
During installation, secrets will be copied to corresponding directories.
You should provide the following secrets:

- github_ssh: private SSH key for GitHub authorization
- argocd_webhook_token: token used to authenticate the ArgoCD webhook
- dockerhub_password: DockerHub token for pushing images from Jenkins build
- github_host_key: GitHub host key for host verification
- docker_config.json: file that holds the Dockerhub authorization token

If you don't need to run the entire installation process but want to provide secrets
to the corresponding directories, you can run "make provide_secrets."

2) Alternatively you can add secrets independently, then place them by next paths:

argocd/secrets/github_ssh - private ssh key for github authorization
argocd/secrets/argocd_webhook_token - token used to authenticate argocd webhook

jenkins/secrets/dockerhub_password - dockerhub token for pushing images from jenkins build
jenkins/secrets/github_host_key - github host key for host verification
jenkins/secrets/github_ssh - private ssh key for github authorization 
jenkins/secrets/argocd_webhook_token - token used to authenticate argocd webhook

preinstall/docker_config.json - file that holds the Dockerhub authorization token 

Also you need to add *.auto.tfvars file to terraform/config with "do_token" variable

PARAMETRIZATION:

The deploy/preinstall directory contains a config.json file with parameters such as hostnames and repoUrl.
This file is used by install scripts to substitute parameters into .yaml files, so during preinstall, it is copied to corresponding directories.
If you don't need to run the entire installation process but want to provide configuration
to the corresponding directories, you can run "make provide_config"
The deploy/preinstall directory also contains utils.sh - script with substitution functions that are used by installation scripts 
"make provide_config" also copies utils.sh to argocd/ jenkins/ elk/ directories,
so it is enough to modify the script in one place, and it will be provided everywhere it is needed

Substitution is done by a bash script function.
You can define additional parameters in config.json and use them in yaml files.
To achieve substitution in yaml files, you need to use the following syntax: <{parameter}>
For nested parameters, use ".", for example, <{argocd.hostname}>.
If a parameter does not exist, the script fails.
If your file contains a sequence of symbols <{}> that should not be replaced, use "/" for escaping it inside <{}>,
For example <{/value}> will turned into <{value}>

To start automatic installation run:
make install
