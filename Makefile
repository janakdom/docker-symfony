CONTAINER_NAME=${COMPOSE_PROJECT_NAME}_web
VENDOR_BIN=/app/vendor/bin
CONSOLE_BIN=php bin/console
SYSTEM_USERNAME=${COMPOSE_USER}

DIR=${CURDIR}

include .docker/.env

PROJECT=-p ${COMPOSE_PROJECT_NAME}
SERVICE=${COMPOSE_PROJECT_NAME}:latest
OPENSSL_BIN:=$(shell which openssl)

INTERACTIVE=
#INTERACTIVE=-T

default:
	down build up-daemon

clean:
	docker system prune

clean-all:
	docker system prune -a

build:
	@docker-compose -f ./.docker/docker-compose.yml build

up-daemon:
	@docker-compose -f ./.docker/docker-compose.yml $(PROJECT) up -d

up:
	@docker-compose -f ./.docker/docker-compose.yml $(PROJECT) up

down:
	@docker-compose -f ./.docker/docker-compose.yml $(PROJECT) down

restart: stop start

bash:
	@docker-compose $(PROJECT) exec $(INTERACTIVE) -u $(SYSTEM_USERNAME) symfony bash

bash-root:
	@docker-compose $(PROJECT) exec $(INTERACTIVE) -u root symfony bash

bash-mysql:
	@docker-compose $(PROJECT) exec mysql bash

exec:
	@docker-compose $(PROJECT) exec $(INTERACTIVE) -u $(SYSTEM_USERNAME) symfony $$cmd

exec-bash:
	@docker-compose $(PROJECT) exec $(INTERACTIVE) -u $(SYSTEM_USERNAME) symfony bash -c "$(cmd)"

exec-by-root:
	@docker-compose $(PROJECT) exec $(INTERACTIVE) symfony $$CMD

env-prod:
	@make -s exec cmd="composer dump-env prod"

env-staging:
	@make -s exec cmd="composer dump-env staging"

composer-install-no-dev:
	@make -s exec-bash cmd="COMPOSER_MEMORY_LIMIT=-1 composer install --optimize-autoloader --no-dev"

composer-install:
	@make -s exec-bash cmd="COMPOSER_MEMORY_LIMIT=-1 composer install --optimize-autoloader"

composer-update:
	@make -s exec-bash cmd="COMPOSER_MEMORY_LIMIT=-1 composer update"

info:
	@make -s exec cmd="composer --version"
	@make -s exec cmd="symfony -V"
	@make -s exec cmd="bin/console --version"
	@make -s exec cmd="php --version"

logs:
	@docker logs -f ${COMPOSE_PROJECT_NAME}_web

logs-db:
	@docker logs -f ${COMPOSE_PROJECT_NAME}_db

logs-mail:
	@docker logs -f ${COMPOSE_PROJECT_NAME}_mailhog

logs-pma:
	@docker logs -f ${COMPOSE_PROJECT_NAME}_pma

migration:
	@make -s exec cmd="${CONSOLE_BIN} make:migration --no-interaction"

migrate:
	@make -s exec cmd="${CONSOLE_BIN} doctrine:migrations:migrate --no-interaction --all-or-nothing"

migration-all:
	migration migrate

fixtures:
	@make -s exec cmd="${CONSOLE_BIN} doctrine:fixtures:load"

analyse:
	@printf '${BIGreen}Running Code quality analyser - PHP Static Analysis Tool\n${BIYellow}===================================================================${Off}\n'
	@make -s exec-bash cmd="/app/scripts/analyse.sh"

deploy-dev:
	@printf '${BIGreen}Compile project to prepare deploy\n${BIYellow}===================================================================${Off}\n'
	@make -s exec-bash cmd="/app/scripts/deploy-dev.sh"

deploy-prod:
	@printf '${BIGreen}Running Code quality analyser - PHP Static Analysis Tool\n${BIYellow}===================================================================${Off}\n'
	@make -s exec-bash cmd="/app/scripts/deploy-prod.sh"


# === Colors ==========================================
# Reset
Off=\033[0m

# Bold High Intensity
BIBlack=\033[1;90m
BIRed=\033[1;91m
BIGreen=\033[1;92m
BIYellow=\033[1;93m
BIBlue=\033[1;94m
BIPurple=\033[1;95m
BICyan=\033[1;96m
BIWhite=\033[1;97m
