# Makefile

.PHONY: install run_scripts preinstall jenkins elk argocd ingress_controller terraform

install: preinstall jenkins elk argocd 

preinstall: install_dependencies_debian terraform ingress_controller preinstall_general provide_config provide_secrets

preinstall_general: preinstall/preinstall_general.sh
	@echo "Preinstalling actions"
	(cd preinstall && bash preinstall_general.sh) 

provide_config: preinstall/provide_config.sh
	@echo "Providing configuration"
	(cd preinstall && bash provide_config.sh) 

provide_secrets: preinstall/provide_secrets.sh
	@echo "Providing secrets"
	(cd preinstall && bash provide_secrets.sh)

jenkins: jenkins/install.sh
	@echo "Installing jenkins..."
	(cd jenkins && bash install.sh)

elk: elk/install.sh
	@echo "Installing elk..."
	(cd elk && bash install.sh)

argocd: argocd/install.sh
	@echo "Installing argocd..."
	(cd argocd && bash install.sh)

ingress_controller: preinstall/ingress-controller.sh
	@echo "Installing ingress-controller.."
	(cd preinstall && bash ingress-controller.sh)

install_dependencies_debian: preinstall/install_dependencies_debian.sh
	@echo "Installing dependencies.."
	(cd preinstall && bash install_dependencies_debian.sh)

terraform: terraform/config/install.sh
	@echo "Running terraform configuration.."
	(cd terraform/config && bash install.sh)