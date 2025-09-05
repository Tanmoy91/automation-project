# Makefile

TF_DIR=./terraform

.PHONY: init plan apply destroy status

init:
	terraform -chdir=$(TF_DIR) init

plan:
	terraform -chdir=$(TF_DIR) plan

apply:
	terraform -chdir=$(TF_DIR) apply -auto-approve

destroy:
	terraform -chdir=$(TF_DIR) destroy -auto-approve

status:
	kubectl get ns
	kubectl get all -n apps
	kubectl get all -n monitoring
	kubectl get all -n jenkins
