.DEFAULT_GOAL := help

help:
	@echo "Commandes disponibles :"
	@echo "  make init     -> initialise Terraform"
	@echo "  make plan     -> affiche le plan Terraform"
	@echo "  make apply    -> applique la configuration Terraform"
	@echo "  make destroy  -> détruit l'infrastructure Terraform"
	@echo "  make fmt      -> formatte les fichiers Terraform"

# Variables
TF_DIR=terraform

# Initialisation de Terraform
init:
	cd $(TF_DIR) && terraform init

# Vérification du plan
plan:
	cd $(TF_DIR) && terraform plan

# Appliquer les changements
apply:
	cd $(TF_DIR) && terraform apply -auto-approve

# Détruire les ressources (attention ⚠️)
destroy:
	cd $(TF_DIR) && terraform destroy -auto-approve

# Formatter les fichiers .tf
fmt:
	cd $(TF_DIR) && terraform fmt
