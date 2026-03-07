# =============================================================================
# Makefile — Docker Compose Stack Management
# Usage: make <target>
# =============================================================================

COMPOSE=docker compose
ENV_FILE=.env

.PHONY: help up down restart logs ps pull update backup clean validate

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

validate: ## Validate docker-compose config
	$(COMPOSE) config --quiet && echo "✅ Config is valid"

up: validate ## Start all services (detached)
	$(COMPOSE) up -d

down: ## Stop all services (keep volumes)
	$(COMPOSE) down

restart: ## Restart all services
	$(COMPOSE) restart

logs: ## Follow logs for all services
	$(COMPOSE) logs -f

ps: ## Show running containers and health
	$(COMPOSE) ps

pull: ## Pull latest images
	$(COMPOSE) pull

update: pull ## Pull images and recreate containers
	$(COMPOSE) up -d --force-recreate

# ---- Individual service controls ----
up-flowise: ## Start only FlowiseAI
	$(COMPOSE) up -d flowise

up-opencti: ## Start only OpenCTI stack
	$(COMPOSE) up -d redis elasticsearch minio rabbitmq opencti opencti-worker

up-directus: ## Start only Directus
	$(COMPOSE) up -d directus

up-metabase: ## Start both Metabase instances
	$(COMPOSE) up -d metabase1 metabase2

# ---- Logs per service ----
logs-flowise:
	$(COMPOSE) logs -f flowise

logs-opencti:
	$(COMPOSE) logs -f opencti opencti-worker

logs-directus:
	$(COMPOSE) logs -f directus

logs-metabase1:
	$(COMPOSE) logs -f metabase1

logs-metabase2:
	$(COMPOSE) logs -f metabase2

logs-traefik:
	$(COMPOSE) logs -f traefik

# ---- Backup volumes ----
backup: ## Backup all named volumes to ./backups/
	@mkdir -p backups
	@echo "Backing up volumes..."
	@for vol in flowise_data flowise_uploads opencti_data elasticsearch_data minio_data directus_uploads directus_extensions metabase1_data metabase2_data; do \
		echo "  → $$vol"; \
		docker run --rm \
			-v $$vol:/source:ro \
			-v $$(pwd)/backups:/backup \
			alpine tar czf /backup/$$vol-$$(date +%Y%m%d_%H%M%S).tar.gz -C /source .; \
	done
	@echo "✅ Backup complete in ./backups/"

clean: ## Remove stopped containers and unused images (CAREFUL)
	docker system prune -f

nuke: ## ⚠️  DANGER: Remove ALL containers, volumes, images for this stack
	$(COMPOSE) down -v --rmi all --remove-orphans
