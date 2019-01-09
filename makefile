# Serverless E-KTP OCR
# MIT License (c) 2018-2019

REQUIRED_BINS 	 := node npm gcloud terraform ls cd pwd rm
$(foreach bin,$(REQUIRED_BINS),\
    $(if $(shell command -v $(bin) 2> /dev/null),$(),$(error Please install `$(bin)`)))


SHELL            := /usr/bin/env bash
PROJECT_NAME     := "ektp-ocr"
TERRAFORM_DIR    := "terraform"

.PHONY: enable
enable:
	-gcloud services enable compute.googleapis.com
	-gcloud services enable cloudfunctions.googleapis.com
	-gcloud services enable pubsub.googleapis.com
	-gcloud services enable storage-api.googleapis.com
	-gcloud services enable storage-component.googleapis.com

.PHONY: create
create:
	-gcloud projects create $(PROJECT_NAME)

.PHONY: init
init:
	terraform init $(TERRAFORM_DIR)

.PHONY: plan
plan:
	terraform plan $(TERRAFORM_DIR)

.PHONY: apply
apply:
	terraform apply -auto-approve $(TERRAFORM_DIR)

.PHONY: deploy
deploy: create init plan apply

.PHONY: destroy
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

.PHONY: clean
clean: clean-tf clean-deps
