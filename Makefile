# tools
SHELL := /bin/bash

# env vars
NB_UID := $(shell id -u)

# Default command and help messages
.PHONY: default help
default: help

bash:      ## Run a bash shell inside the app container
up:        ## Launch the dev environment

.PHONY: up
up:
				docker-compose -p ${USER} up

.PHONY: down
down:
				docker-compose -p ${USER} down

.PHONY: pull
pull:
				docker-compose pull

.PHONY: bash
bash:
				@docker-compose -p ${USER} exec notebook bash

.PHONY: ipython
ipython:
				@docker-compose -p ${USER} exec notebook bash -c "docker-entrypoint.sh /opt/conda/envs/python2/bin/ipython"

.PHONY: ipython3
ipython3:
				@docker-compose -p ${USER} exec notebook ipython3

.PHONY: julia
julia:
				@docker-compose -p ${USER} exec notebook bash -c "docker-entrypoint.sh julia"
