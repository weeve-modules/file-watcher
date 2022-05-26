# import config.
# You can change the default config with `make cnf="config_special.env" build`
cnf ?= config.env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

# import deploy config
# You can change the default deploy config with `make cnf="deploy_special.env" release`
dpl ?= deploy.env
include $(dpl)
export $(shell sed 's/=.*//' $(dpl))

# # grep the version from the mix file
# VERSION=$(shell ./version.sh)

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help


# DOCKER TASKS
# Build the container
build: ## Build the container
	docker build -t $(ACCOUNT_NAME)/$(APP_NAME) . -f image/Dockerfile

build-force: ## Build the container
	docker build --no-cache -t $(ACCOUNT_NAME)/$(APP_NAME) . -f image/Dockerfile

# build-nc: ## Build the container without caching
# 	docker build --no-cache -t $(APP_NAME) .

run: ## Run container
	docker run --rm --env-file=./config.env \
		--volume $(DEVICE_MOUNT_HOST):$(DEVICE_MOUNT_CONTAINER) \
		--name="$(APP_NAME)" \
		$(ACCOUNT_NAME)/$(APP_NAME) --hash sha256 --interval=2

listen: ## Pull and start a listener container
	docker run --detach -e PORT=$(PORT) -e LOG_HTTP_BODY -e LOG_HTTP_HEADERS -p $(PORT):$(PORT) jmalloc/echo-server

up: build run ## Run container on port configured in `config.env` (Alias to run)

# check:
# 	docker pushrm2 --version
# ifeq (, $(shell which docker pushrm))
# $(error "No lzop in $(PATH), consider doing apt-get install lzop")
# endif

listentest: ## Run a listener container and receive messages from this container
	docker network create $(NETWORK_NAME) || true
	docker stop echo || echo ""
	docker run --detach --network=$(NETWORK_NAME) --rm \
		-e PORT=9001 \
		-e LOG_HTTP_BODY=true \
		-e LOG_HTTP_HEADERS=true \
		--name echo jmalloc/echo-server

	docker run --network=$(NETWORK_NAME) --rm \
		--volume $(DEVICE_MOUNT_HOST):$(DEVICE_MOUNT_CONTAINER) \
		-e MODULE_NAME=dev-random \
		-e MODULE_TYPE=INGRESS \
		-e EGRESS_URL=http://echo:9001 \
		-e DEVICE_MOUNT_HOST=/dev/urandom \
		-e DEVICE_MOUNT_CONTAINER=/mnt/random \
		$(ACCOUNT_NAME)/$(APP_NAME) --hash sha256 --interval=2

push: ## Push to dockerhub, needs credentials!
	docker push $(ACCOUNT_NAME)/$(APP_NAME):latest

pushrm: ## Push to dockerhub AND add description, needs additionally the pushrm tool!
## https://github.com/christian-korneck/docker-pushrm
	docker push $(ACCOUNT_NAME)/$(APP_NAME):latest
	docker pushrm $(ACCOUNT_NAME)/$(APP_NAME):latest --short $(DESCRIPTION)

# docker run --rm -t \
# 	-v $(pwd):/myvol \
# 	-e DOCKER_USER='my-user' -e DOCKER_PASS='my-pass' \
# 	chko/docker-pushrm:1 --file /myvol/README.md \
# 	--short "My short description" --debug my-user/my-repo
# stop: ## Stop and remove a running container
# 	docker stop $(APP_NAME); docker rm $(APP_NAME)

# release: build-nc publish ## Make a release by building and publishing the `{version}` ans `latest` tagged containers to ECR

# Docker publish
# publish: repo-login publish-latest publish-version ## Publish the `{version}` ans `latest` tagged containers to ECR

# publish-latest: tag-latest ## Publish the `latest` taged container to ECR
# 	@echo 'publish latest to $(DOCKER_REPO)'
# 	docker push $(DOCKER_REPO)/$(APP_NAME):latest

# publish-version: tag-version ## Publish the `{version}` taged container to ECR
# 	@echo 'publish $(VERSION) to $(DOCKER_REPO)'
# 	docker push $(DOCKER_REPO)/$(APP_NAME):$(VERSION)

# # Docker tagging
# tag: tag-latest tag-version ## Generate container tags for the `{version}` ans `latest` tags

# tag-latest: ## Generate container `{version}` tag
# 	@echo 'create tag latest'
# 	docker tag $(APP_NAME) $(DOCKER_REPO)/$(APP_NAME):latest

# tag-version: ## Generate container `latest` tag
# 	@echo 'create tag $(VERSION)'
# 	docker tag $(APP_NAME) $(DOCKER_REPO)/$(APP_NAME):$(VERSION)

# # HELPERS

# # generate script to login to aws docker repo
# CMD_REPOLOGIN := "eval $$\( aws ecr"
# ifdef AWS_CLI_PROFILE
# CMD_REPOLOGIN += " --profile $(AWS_CLI_PROFILE)"
# endif
# ifdef AWS_CLI_REGION
# CMD_REPOLOGIN += " --region $(AWS_CLI_REGION)"
# endif
# CMD_REPOLOGIN += " get-login --no-include-email \)"

# # login to AWS-ECR
# repo-login: ## Auto login to AWS-ECR unsing aws-cli
# 	@eval $(CMD_REPOLOGIN)

# version: ## Output the current version
# 	@echo $(VERSION)

build_and_push_multi_platform:
	docker buildx build --platform linux/amd64,linux/arm,linux/arm64 -t $(ACCOUNT_NAME)/$(APP_NAME):latest --push . -f image/Dockerfile
	docker pushrm $(ACCOUNT_NAME)/$(APP_NAME):latest --short $(DESCRIPTION)

.phony: create_and_push_multi_platform


# OLD
# ### THIS IS THE VERSION WITH docker-compose

# # import config.
# # You can change the default config with `make cnf="config_special.env" build`
# cnf ?= config.env
# include $(cnf)
# export $(shell sed 's/=.*//' $(cnf))

# # import deploy config
# # You can change the default deploy config with `make cnf="deploy_special.env" release`
# dpl ?= deploy.env
# include $(dpl)
# export $(shell sed 's/=.*//' $(dpl))

# # grep the version from the mix file
# VERSION=$(shell ./version.sh)

# # HELP
# # This will output the help for each task
# # thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
# .PHONY: help

# help: ## This help.
# 	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# .DEFAULT_GOAL := help



# # DOCKER TASKS

# # Build the container
# build: ## Build the release and develoment container. The development
# 	docker-compose build --no-cache $(APP_NAME)
# 	docker-compose run $(APP_NAME) grunt build
# 	docker build -t $(APP_NAME) .


# run: stop ## Run container on port configured in `config.env`
# 	docker run -i -t --rm --env-file=./config.env -p=$(PORT):$(PORT) --name="$(APP_NAME)" $(APP_NAME)


# dev: ## Run container in development mode
# 	docker-compose build --no-cache $(APP_NAME) && docker-compose run $(APP_NAME)

# # Build and run the container
# up: ## Spin up the project
# 	docker-compose up --build $(APP_NAME)

# stop: ## Stop running containers
# 	docker stop $(APP_NAME)

# rm: stop ## Stop and remove running containers
# 	docker rm $(APP_NAME)

# clean: ## Clean the generated/compiles files
# 	echo "nothing clean ..."

# # Docker release - build, tag and push the container
# release: build publish ## Make a release by building and publishing the `{version}` ans `latest` tagged containers to ECR

# # Docker publish
# publish: repo-login publish-latest publish-version ## publish the `{version}` ans `latest` tagged containers to ECR

# publish-latest: tag-latest ## publish the `latest` taged container to ECR
# 	@echo 'publish latest to $(DOCKER_REPO)'
# 	docker push $(DOCKER_REPO)/$(APP_NAME):latest

# publish-version: tag-version ## publish the `{version}` taged container to ECR
# 	@echo 'publish $(VERSION) to $(DOCKER_REPO)'
# 	docker push $(DOCKER_REPO)/$(APP_NAME):$(VERSION)

# # Docker tagging
# tag: tag-latest tag-version ## Generate container tags for the `{version}` ans `latest` tags

# tag-latest: ## Generate container `{version}` tag
# 	@echo 'create tag latest'
# 	docker tag $(APP_NAME) $(DOCKER_REPO)/$(APP_NAME):latest

# tag-version: ## Generate container `latest` tag
# 	@echo 'create tag $(VERSION)'
# 	docker tag $(APP_NAME) $(DOCKER_REPO)/$(APP_NAME):$(VERSION)



# # HELPERS

# # generate script to login to aws docker repo
# CMD_REPOLOGIN := "aws ecr"
# ifdef AWS_CLI_PROFILE
# CMD_REPOLOGIN += "--profile $(AWS_CLI_PROFILE)"
# endif
# ifdef AWS_CLI_REGION
# CMD_REPOLOGIN += "--region $(AWS_CLI_REGION)"
# endif
# CMD_REPOLOGIN += "get-login --no-include-email"

# repo-login: ## Auto login to AWS-ECR unsing aws-cli
# 	@eval $(CMD_REPOLOGIN)

# version: ## output to version
# 	@echo $(VERSION)