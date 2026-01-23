# ============================================
# Alfred Project - Docker Management Makefile
# ============================================

.PHONY: help dev prod build up down restart logs clean init-env init-ssl migrate seed

# Default environment
ENV_FILE ?= .env

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(GREEN)Alfred Project - Docker Management$(NC)"
	@echo ""
	@echo "$(YELLOW)Development Commands:$(NC)"
	@echo "  make dev              - Start development environment"
	@echo "  make dev-up           - Start dev services"
	@echo "  make dev-down         - Stop dev services"
	@echo "  make dev-logs         - View dev logs"
	@echo "  make dev-tools        - Start dev tools (pgAdmin, Redis Commander)"
	@echo ""
	@echo "$(YELLOW)Production Commands:$(NC)"
	@echo "  make prod             - Start production environment"
	@echo "  make prod-build       - Build production images"
	@echo "  make prod-up          - Start production services"
	@echo "  make prod-down        - Stop production services"
	@echo "  make prod-logs        - View production logs"
	@echo ""
	@echo "$(YELLOW)Database Commands:$(NC)"
	@echo "  make db-backup        - Backup database"
	@echo "  make db-restore       - Restore database from backup"
	@echo ""
	@echo "$(YELLOW)Utility Commands:$(NC)"
	@echo "  make build            - Build all services"
	@echo "  make clean            - Clean up containers and volumes"
	@echo "  make init-env         - Initialize environment files"

# ============================================
# Development Environment
# ============================================

dev: init-env ## Start complete development environment
	@echo "$(GREEN)Starting Alfred Development Environment...$(NC)"
	docker compose --env-file .env up -d
	@echo "$(GREEN)Development environment is running!$(NC)"
	@echo ""
	@echo "$(YELLOW)Services:$(NC)"
	@echo "  - Gateway API:    http://localhost:8000"
	@echo "  - Identity API:   http://localhost:5001"
	@echo "  - PostgreSQL:     localhost:5432"
	@echo "  - Redis:          localhost:6379"
	@echo ""
	@echo "$(YELLOW)Use 'make dev-tools' to start management tools$(NC)"

dev-up: ## Start development services
	docker compose --env-file .env up -d

dev-down: ## Stop development services
	docker compose --env-file .env down

dev-restart: ## Restart development services
	docker compose --env-file .env restart

dev-logs: ## View development logs
	docker compose --env-file .env logs -f

dev-tools: ## Start development tools (pgAdmin, Redis Commander)
	@echo "$(GREEN)Starting development tools...$(NC)"
	docker compose --env-file .env --profile tools up -d
	@echo "$(GREEN)Tools are running!$(NC)"
	@echo ""
	@echo "$(YELLOW)Management Tools:$(NC)"
	@echo "  - pgAdmin:         http://localhost:5050"
	@echo "  - Redis Commander: http://localhost:8081"

# ============================================
# Production Environment
# ============================================

prod: init-env prod-build ## Start complete production environment
	@echo "$(GREEN)Starting Alfred Production Environment...$(NC)"
	docker compose -f docker-compose.prod.yml --env-file .env.prod up -d
	@echo "$(GREEN)Production environment is running!$(NC)"

prod-build: ## Build production images
	@echo "$(GREEN)Building production images...$(NC)"
	docker compose -f docker-compose.prod.yml --env-file .env.prod build --no-cache

prod-up: ## Start production services
	docker compose -f docker-compose.prod.yml --env-file .env.prod up -d

prod-down: ## Stop production services
	docker compose -f docker-compose.prod.yml --env-file .env.prod down

prod-restart: ## Restart production services
	docker compose -f docker-compose.prod.yml --env-file .env.prod restart

prod-logs: ## View production logs
	docker compose -f docker-compose.prod.yml --env-file .env.prod logs -f

# ============================================
# Database Management
# ============================================

migrate: ## Run database migrations
	@echo "$(GREEN)Running database migrations...$(NC)"
	docker compose exec alfred-identity dotnet ./cli/Alfred.Identity.Cli.dll migrate
	@echo "$(GREEN)Migrations completed!$(NC)"

seed: ## Seed database with initial data
	@echo "$(GREEN)Seeding database...$(NC)"
	docker compose exec alfred-identity dotnet ./cli/Alfred.Identity.Cli.dll seed
	@echo "$(GREEN)Seeding completed!$(NC)"

# Database Management - Development
dev-db-backup: ## Backup Development DB
	@echo "$(GREEN)Creating Development DB backup (Custom Format)...$(NC)"
	@mkdir -p ./backups/dev
	docker compose --env-file .env exec -T postgres sh -c 'pg_dump -Fc -U $$POSTGRES_USER $$POSTGRES_DB' > ./backups/dev/backup-$(shell date +%Y%m%d-%H%M%S).dump
	@echo "$(GREEN)Backup created in ./backups/dev/$(NC)"

dev-db-restore: ## Restore Development DB (specify BACKUP_FILE=filename.dump)
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "$(RED)Error: Please specify BACKUP_FILE=filename.dump$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Restoring Development DB from $(BACKUP_FILE)...$(NC)"
	docker compose --env-file .env exec -T postgres sh -c 'pg_restore --clean --if-exists -U $$POSTGRES_USER -d $$POSTGRES_DB' < ./backups/dev/$(BACKUP_FILE)
	@echo "$(GREEN)Database restored!$(NC)"

# Database Management - Production
prod-db-backup: ## Backup Production DB
	@echo "$(GREEN)Creating Production DB backup (Custom Format)...$(NC)"
	@mkdir -p ./backups/prod
	docker compose -f docker-compose.prod.yml --env-file .env.prod exec -T postgres sh -c 'pg_dump -Fc -U $$POSTGRES_USER $$POSTGRES_DB' > ./backups/prod/backup-$(shell date +%Y%m%d-%H%M%S).dump
	@echo "$(GREEN)Backup created in ./backups/prod/$(NC)"

prod-db-restore: ## Restore Production DB (specify BACKUP_FILE=filename.dump)
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "$(RED)Error: Please specify BACKUP_FILE=filename.dump$(NC)"; \
		exit 1; \
	fi
	@echo "$(RED)WARNING: You are about to restore the PRODUCTION database!$(NC)"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@echo "$(YELLOW)Restoring Production DB from $(BACKUP_FILE)...$(NC)"
	docker compose -f docker-compose.prod.yml --env-file .env.prod exec -T postgres sh -c 'pg_restore --clean --if-exists -U $$POSTGRES_USER -d $$POSTGRES_DB' < ./backups/prod/$(BACKUP_FILE)
	@echo "$(GREEN)Database restored!$(NC)"

# ============================================
# Build & Utility Commands
# ============================================

build: ## Build all services
	@echo "$(GREEN)Building all services...$(NC)"
	docker compose build --no-cache

ps: ## Show running containers
	@docker compose ps

shell-gateway: ## Shell into gateway container
	docker compose exec alfred-gateway sh

shell-identity: ## Shell into identity container
	docker compose exec alfred-identity sh

shell-postgres: ## Shell into postgres container
	docker compose exec postgres psql -U ${POSTGRES_USER:-alfred} ${POSTGRES_DB:-alfred_db}

# ============================================
# Cleanup Commands
# ============================================

clean: ## Clean up containers, volumes, and images
	@echo "$(YELLOW)Stopping all containers...$(NC)"
	docker compose down -v
	@echo "$(YELLOW)Removing unused images...$(NC)"
	docker image prune -f
	@echo "$(GREEN)Cleanup completed!$(NC)"

clean-all: ## Deep clean (WARNING: removes ALL Alfred data)
	@echo "$(RED)WARNING: This will remove all containers, volumes, and data!$(NC)"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	docker compose down -v --remove-orphans
	docker volume rm alfred-postgres-data alfred-redis-data 2>/dev/null || true
	docker image rm alfred-identity alfred-gateway 2>/dev/null || true
	@echo "$(GREEN)Deep clean completed!$(NC)"

# ============================================
# Initialization Commands
# ============================================

init-env: ## Initialize environment files
	@if [ ! -f .env ]; then \
		echo "$(YELLOW)Creating .env file from template...$(NC)"; \
		cp .env.example .env; \
		echo "$(GREEN).env file created! Please update with your values.$(NC)"; \
	else \
		echo "$(GREEN).env file already exists.$(NC)"; \
	fi
	@if [ ! -f .env.prod ]; then \
		echo "$(YELLOW)Creating .env.prod file from template...$(NC)"; \
		cp .env.prod.example .env.prod; \
		echo "$(YELLOW)⚠️  IMPORTANT: Update .env.prod with production values!$(NC)"; \
	fi

init-ssl: ## Initialize SSL certificates directory
	@echo "$(GREEN)Creating SSL directories...$(NC)"
	@mkdir -p ./nginx/ssl
	@echo "$(YELLOW)Please place your SSL certificates in ./nginx/ssl/$(NC)"
	@echo "  - fullchain.pem"
	@echo "  - privkey.pem"
	@echo ""
	@echo "$(YELLOW)Or use Let's Encrypt with:$(NC)"
	@echo "  certbot certonly --webroot -w ./nginx/ssl -d yourdomain.com"

# ============================================
# Monitoring Commands
# ============================================

stats: ## Show container resource usage
	docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

health: ## Check health status of all services
	@echo "$(GREEN)Checking service health...$(NC)"
	@docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

# ============================================
# Deployment Commands
# ============================================

deploy-dev: clean dev ## Clean and deploy development environment
	@echo "$(GREEN)Development environment deployed!$(NC)"

deploy-prod: init-ssl prod-build prod-up ## Deploy production environment
	@echo "$(GREEN)Production environment deployed!$(NC)"
	@echo "$(YELLOW)Remember to:$(NC)"
	@echo "  1. Run migrations: make migrate"
	@echo "  2. Seed data: make seed"
	@echo "  3. Configure DNS to point to your server"
