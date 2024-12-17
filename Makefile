AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --query Account --output text)
AWS_REGION := $(shell aws configure get region)
ARTIFACT_NAME := lambda-ecs-test
ARTIFACT_VERSION := $(shell git rev-parse --short HEAD)
DEPLOYMENT_TYPE := Lambda

src/static-app/build:
	@cd src/static-app && npm run build

build-app: src/static-app/build

build-app-clean:
	@rm -rf src/static-app/build

build-app-rebuild: build-app-clean build-app

build: build-app ## Build the container image
	@docker build -t $(ARTIFACT_NAME):$(ARTIFACT_VERSION) .

push: ## Push the container image to ECR
	@docker tag $(ARTIFACT_NAME):$(ARTIFACT_VERSION) $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(ARTIFACT_NAME):$(ARTIFACT_VERSION)
	@docker push $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(ARTIFACT_NAME):$(ARTIFACT_VERSION)

ecr-login: ## Login to ECR
	@aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

run-local: ## Run the lambda locally
	@docker run -p 8080:8080 --rm $(ARTIFACT_NAME):$(ARTIFACT_VERSION) lambda-function.handler

exec-local: ## Execute the lambda locally
	@curl -XPOST "http://localhost:8080/2015-03-31/functions/function/invocations" \
		-H "Content-Type: application/json" \
		-d '{"httpMethod": "GET", "path": "index.html"}'
	@# To see the file contents you can pipe the response through jq and base64 decode it:
	@# $ make exec-local | jq .body -r | base64 -d

run-nginx-local: ## Run the nginx service locally
	@docker run -d -p 8080:8080 --entrypoint="" --rm --name $(ARTIFACT_NAME)-local $(ARTIFACT_NAME):$(ARTIFACT_VERSION) /nginx-start.sh

stop-nginx-local: ## Stop the nginx service locally
	@docker stop $(ARTIFACT_NAME)-local

exec-nginx-local: ## Execute a request to nginx locally
	@curl -XGET "http://localhost:8080"

deploy-validate: ## Validate the CloudFormation template
	@aws cloudformation validate-template --template-body file://./cloudformation/prerequisite.yaml
	@aws cloudformation validate-template --template-body file://./cloudformation/workload.yaml

deploy-prereq: ## Deploy the prerequisites
	@aws cloudformation deploy \
		--template-file ./cloudformation/prerequisite.yaml \
		--stack-name $(ARTIFACT_NAME)-prereq \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameter-overrides \
			RepositoryName=$(ARTIFACT_NAME)

deploy-workload: ## Deploy the workload
	@aws cloudformation deploy \
		--template-file ./cloudformation/workload.yaml \
		--stack-name $(ARTIFACT_NAME)-workload \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameter-overrides \
			RepositoryName=$(ARTIFACT_NAME) \
			ArtifactVersion=$(ARTIFACT_VERSION) \
			VpcId=$(shell aws ec2 describe-vpcs --query 'Vpcs[0].VpcId' --output text) \
			SubnetIds="$(shell aws ec2 describe-subnets --query 'Subnets[*].SubnetId' --output text | tr '\t' ',')" \
			DeploymentType=$(DEPLOYMENT_TYPE)

deploy-clean: ## Clean up the existing stack
	@aws cloudformation delete-stack --stack-name $(ARTIFACT_NAME)-workload
	@aws cloudformation wait stack-delete-complete --stack-name $(ARTIFACT_NAME)-workload
	@aws cloudformation delete-stack --stack-name $(ARTIFACT_NAME)-prereq
	@aws cloudformation wait stack-delete-complete --stack-name $(ARTIFACT_NAME)-prereq

browser-test-local: run-nginx-local ## Run K6 browser test locally
	@sleep 4 # warm-up time
	@k6 run --out csv=load_testing/results/browser-test-results-$(shell date +%Y-%m-%d-%H-%M-%S).csv load_testing/browser.js
	$(MAKE) stop-nginx-local

browser-test-aws-local: ## Run browser testing locally targeting the AWS deployment
	@k6 run --out csv=load_testing/results/browser-test-results-aws-$(shell date +%Y-%m-%d-%H-%M-%S).csv --env 'TARGET_URL=http://$(shell aws cloudformation describe-stacks --stack-name $(ARTIFACT_NAME)-workload --query 'Stacks[].Outputs[?OutputKey==`LoadBalancerDnsName`].OutputValue' --output text)' load_testing/browser.js

browser-test-aws-cloud: ## Run browser testing on Grafana Cloud targeting the AWS deployment
	@k6 cloud run --env 'TARGET_URL=http://$(shell aws cloudformation describe-stacks --stack-name $(ARTIFACT_NAME)-workload --query 'Stacks[].Outputs[?OutputKey==`LoadBalancerDnsName`].OutputValue' --output text)' load_testing/browser.js

load-test-local: run-nginx-local ## Run load testing locally
	@sleep 4 # warm-up time
	@k6 run --out csv=load_testing/results/http-test-results-$(shell date +%Y-%m-%d-%H-%M-%S).csv load_testing/http.js
	$(MAKE) stop-nginx-local

load-test-aws-local: ## Run load testing locally targeting the AWS deployment
	@k6 run --out csv=load_testing/results/http-test-results-aws-$(shell date +%Y-%m-%d-%H-%M-%S).csv --env 'TARGET_URL=http://$(shell aws cloudformation describe-stacks --stack-name $(ARTIFACT_NAME)-workload --query 'Stacks[].Outputs[?OutputKey==`LoadBalancerDnsName`].OutputValue' --output text)' load_testing/http.js

load-test-aws-cloud: ## Run load testing on Grafana Cloud targeting the AWS deployment
	@k6 cloud run --env PROFILE=cloud --env 'TARGET_URL=http://$(shell aws cloudformation describe-stacks --stack-name $(ARTIFACT_NAME)-workload --query 'Stacks[].Outputs[?OutputKey==`LoadBalancerDnsName`].OutputValue' --output text)' load_testing/http.js

help: ## Display this help message
	@echo "====="
	@echo "Tasks"
	@echo "====="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
.DEFAULT_GOAL := help
