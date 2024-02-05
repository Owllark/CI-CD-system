# Makefile

SCRIPTS := preinstall/preinstall.sh jenkins/install.sh elk/install.sh argocd/install.sh

.PHONY: install run_scripts preinstall jenkins elk argocd

install: run_scripts

run_scripts:
	@for script in $(SCRIPTS); do \
		echo "Running $$script"; \
		(cd $$(dirname $$script) && bash $$(basename $$script)); \
	done

preinstall: preinstall/preinstall.sh
	@echo "Preinstalling actions"
	(cd preinstall && bash preinstall.sh)

jenkins: jenkins/install.sh
	@echo "Installing jenkins..."
	(cd jenkins && bash install.sh)

elk: elk/install.sh
	@echo "Installing elk..."
	(cd elk && bash install.sh)

argocd: argocd/install.sh
	@echo "Installing argocd..."
	(cd argocd && bash install.sh)

ingress-controller: preinstall/ingress-controller.sh
	@echo "Installing ingress-controller.."
	bash preinstall/ingress-controller.sh
