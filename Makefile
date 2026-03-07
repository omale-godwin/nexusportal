# =============================================================================
# Makefile - Stack Management
# =============================================================================
COMPOSE=docker compose

.PHONY: help up down restart logs ps pull update backup

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS=":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

validate: ## Validate compose config
	$(COMPOSE) config --quiet && echo "Config is valid"

up: validate ## Start all services
	$(COMPOSE) up -d

down: ## Stop all (keep volumes)
	$(COMPOSE) down

restart: ## Restart all
	$(COMPOSE) restart

logs: ## Follow all logs
	$(COMPOSE) logs -f

ps: ## Show status and health
	$(COMPOSE) ps

pull: ## Pull latest images
	$(COMPOSE) pull

update: pull ## Pull + recreate containers
	$(COMPOSE) up -d --force-recreate

# Individual service controls
up-flowise:    ; $(COMPOSE) up -d flowise
up-openclaw:   ; $(COMPOSE) up -d openclaw-gateway
up-directus:   ; $(COMPOSE) up -d directus
up-metabase:   ; $(COMPOSE) up -d metabase1 metabase2

logs-flowise:  ; $(COMPOSE) logs -f flowise
logs-openclaw: ; $(COMPOSE) logs -f openclaw-gateway
logs-directus: ; $(COMPOSE) logs -f directus
logs-metabase1:; $(COMPOSE) logs -f metabase1
logs-metabase2:; $(COMPOSE) logs -f metabase2
logs-nginx:    ; $(COMPOSE) logs -f nginx

# OpenClaw CLI helpers (requires --profile cli)
cli-up: ## Start OpenClaw CLI sidecar
	$(COMPOSE) --profile cli up -d openclaw-cli

cli-dashboard: ## Get OpenClaw dashboard URL+token
	$(COMPOSE) exec openclaw-cli node dist/index.js dashboard --no-open

cli-channels: ## List configured channels
	$(COMPOSE) exec openclaw-cli node dist/index.js channels list

cli-devices: ## List paired devices
	$(COMPOSE) exec openclaw-cli node dist/index.js devices list

backup: ## Backup all volumes to ./backups/
	@mkdir -p backups
	@for vol in flowise_data flowise_uploads openclaw_config openclaw_workspace openclaw_data directus_uploads directus_extensions metabase1_data metabase1_plugins metabase2_data metabase2_plugins; do \
		echo "Backing up $$vol..."; \
		docker run --rm -v $$vol:/src:ro -v $$(pwd)/backups:/dst alpine \
			tar czf /dst/$$vol-$$(date +%Y%m%d_%H%M%S).tar.gz -C /src .; \
	done
	@echo "Backup complete in ./backups/"

nuke: ## DANGER: Remove all containers + volumes
	$(COMPOSE) down -v --rmi all --remove-orphans
