SHELL=/bin/bash
.PHONY: help publish test

help: ## Show this help
	@echo "Targets:"
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/\(.*\):.*##[ \t]*/    \1 ## /' | sort | column -t -s '##'

up: ## Start containers
	docker-compose up -d

down: ## Stops containers
	docker-compose down

restart: down up ## Restart containers

clear-db: ## Clears local db
	bash -c "rm -rf .docker"

build: ## Rebuild containers
	docker-compose build --no-cache

complete-restart: clear-db down up    ## Clear DB and restart containers

publish: ## Build and publish plugin to luarocks
	docker-compose run kong bash -c "cd /kong-plugins && chmod +x publish.sh && ./publish.sh"

test: ## Run tests
	docker-compose run kong bash -c "cd /kong && bin/kong migrations up && bin/busted /kong-plugins/spec"
	docker-compose down

coverage: ## Run coverage
	docker-compose run kong bash -c "cd /kong && bin/kong migrations up && bin/busted --coverage /kong-plugins/spec && luacov '/kong_client/*' && cat luacov.report.out"
	docker-compose down

ssh: ## Pings kong on localhost:8000
	docker-compose run kong bash

db: ## Access DB
	docker-compose run kong bash -c "psql -h kong-database -U kong"
