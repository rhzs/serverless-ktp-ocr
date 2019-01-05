# Serverless E-KTP OCR
# MIT License (c) 2018-2019

REQUIRED_BINS 	 := node npm gcloud terraform ls cd pwd rm
$(foreach bin,$(REQUIRED_BINS),\
    $(if $(shell command -v $(bin) 2> /dev/null),$(),$(error Please install `$(bin)`)))


SHELL            := /usr/bin/env bash
PROJECT_NAME     := "ektp-ocr"
TERRAFORM_DIR    := "terraform"

create:
	-gcloud projects create $(PROJECT_NAME)

init:
	terraform init $(TERRAFORM_DIR)

plan:
	terraform plan $(TERRAFORM_DIR)

apply:
	terraform apply -auto-approve $(TERRAFORM_DIR)

deploy: 

destroy:
	terraform destroy -auto-approve $(TERRAFORM_DIR)

clean-tf: 
	-rm -fr .terraform
	-rm -fr ./terraform/dist
	-rm *.tfstate
	-rm *.backup

clean-deps:
	-rm -fr ./http-ktp/node_modules
	-rm -fr ./ktp-image-event-trigger/node_modules

clean: clean-tf clean-deps
