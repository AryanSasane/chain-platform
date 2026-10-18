.RECIPEPREFIX = >
.PHONY: up down logs reset

COMPOSE = docker compose --env-file .env.example -f infra/compose/compose.chain.yml

up:
> $(COMPOSE) up -d

down:
> $(COMPOSE) down

logs:
> $(COMPOSE) logs -f --tail=50

reset:
> $(COMPOSE) down -v
> ./chain/scripts/generate-dev-network.sh
> $(COMPOSE) up -d
