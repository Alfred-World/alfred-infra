# ============================================
# Alfred Project - Docker Management Makefile
# ============================================

.PHONY: help dev prod build up down restart logs clean init-env init-ssl migrate seed
.PHONY: dev-up dev-down dev-restart dev-logs dev-tools dev-db-backup dev-db-restore
.PHONY: prod-build prod-up prod-down prod-restart prod-logs prod-deploy prod-migrate prod-seed prod-health
.PHONY: prod-db-backup prod-db-restore prod-init-db
.PHONY: shell-gateway shell-identity shell-core shell-notification shell-postgres shell-redis
.PHONY: mtls-certs mtls-test stats health ps clean-all deploy-dev deploy-prod init-env init-ssl

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
	@echo "  make dev              - Start dev infrastructure (PostgreSQL + Redis)"
	@echo "  make dev-up           - Start dev services"
	@echo "  make dev-down         - Stop dev services"
	@echo "  make dev-logs         - View dev logs"
	@echo "  make dev-tools        - Start dev tools (pgAdmin, Redis Commander)"
	@echo "  make dev-db-backup    - Backup dev database"
	@echo "  make dev-db-restore   - Restore dev database"
	@echo ""
	@echo "$(YELLOW)Production Commands (Full Stack: 4 BE + 2 FE):$(NC)"
	@echo "  make prod-deploy      - Build & deploy all services (recommended)"
	@echo "  make prod-build       - Build all production images"
	@echo "  make prod-up          - Start production services"
	@echo "  make prod-down        - Stop production services"
	@echo "  make prod-restart     - Restart production services"
	@echo "  make prod-logs        - View production logs"
	@echo "  make prod-health      - Check production services health"
	@echo "  make prod-init-db     - Create databases for existing postgres"
	@echo "  make prod-migrate     - Run all database migrations"
	@echo "  make prod-seed        - Seed production database"
	@echo ""
	@echo "$(YELLOW)mTLS Commands:$(NC)"
	@echo "  make mtls-certs       - Generate mTLS certificates (10-year validity)"
	@echo "  make mtls-test        - Test mTLS configuration"
	@echo ""
	@echo "$(YELLOW)Database Commands:$(NC)"
	@echo "  make dev-db-backup    - Backup dev database"
	@echo "  make dev-db-restore   - Restore dev database"
	@echo "  make prod-db-backup   - Backup all production databases"
	@echo "  make prod-db-restore  - Restore production database"
	@echo ""
	@echo "$(YELLOW)Shell Commands (Production):$(NC)"
	@echo "  make shell-gateway    - Shell into gateway container"
	@echo "  make shell-identity   - Shell into identity container"
	@echo "  make shell-core       - Shell into core container"
	@echo "  make shell-notification - Shell into notification container"
	@echo "  make shell-postgres   - psql into postgres"
	@echo "  make shell-redis      - redis-cli into redis"
	@echo ""
	@echo "$(YELLOW)Utility Commands:$(NC)"
	@echo "  make build            - Build all production service images"
	@echo "  make ps               - Show running containers"
	@echo "  make stats            - Show container resource usage"
	@echo "  make health           - Check dev service health"
	@echo "  make clean            - Clean up dev containers and volumes"
	@echo "  make clean-all        - Deep clean (WARNING: removes ALL Alfred data)"
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
	@echo "  - PostgreSQL:     localhost:5432"
	@echo "  - Redis:          localhost:6379"
	@echo ""
	@echo "$(YELLOW)Note: Backend services run locally via 'make run' in each service folder$(NC)"
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

prod: init-env mtls-certs prod-build ## Start complete production environment with mTLS
	@echo "$(GREEN)Starting Alfred Production Environment with mTLS...$(NC)"
	@echo "MTLS_ENABLED=true" >> .env.prod
	docker compose -f docker-compose.prod.yml --env-file .env.prod up -d
	@echo "$(GREEN)Production environment is running with mTLS enabled!$(NC)"
	@echo ""
	@echo "$(YELLOW)Services:$(NC)"
	@echo "  - Gateway:         http://localhost:8000"
	@echo "  - Identity HTTPS:  https://alfred-identity:8101 (mTLS)"
	@echo "  - Core HTTPS:      https://alfred-core:8201 (mTLS)"

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

prod-deploy: init-env mtls-certs prod-build ## Deploy full stack with mTLS (one command)
	@echo "$(GREEN)Deploying Full Stack Production Environment...$(NC)"
	docker compose -f docker-compose.prod.yml --env-file .env.prod up -d
	@echo "$(GREEN)✅ Production deployed! (4 BE + 2 FE + Infra)$(NC)"
	@echo ""
	@echo "$(YELLOW)Services:$(NC)"
	@echo "  - Gateway:           http://localhost:8000"
	@echo "  - Identity (mTLS):   https://alfred-identity:8101"
	@echo "  - Core (mTLS):       https://alfred-core:8201"
	@echo "  - Notification:      http://alfred-notification:8300"
	@echo "  - SSO Web:           http://localhost:3100"
	@echo "  - Core Web:          http://localhost:3200"
	@echo ""
	@echo "$(YELLOW)Next steps:$(NC)"
	@echo "  1. Check health:  make prod-health"
	@echo "  2. View logs:     make prod-logs"
	@echo "  3. Run migrations: make prod-migrate"

# ============================================
# mTLS Commands
# ============================================

mtls-certs: ## Generate mTLS certificates (10-year validity)
	@if [ ! -f ./certificates/ca/ca.crt ]; then \
		echo "$(GREEN)Generating mTLS certificates...$(NC)"; \
		cd certificates && chmod +x generate-certs.sh && ./generate-certs.sh; \
		echo "$(GREEN)✅ Certificates generated!$(NC)"; \
	else \
		echo "$(GREEN)✅ Certificates already exist$(NC)"; \
	fi

mtls-test: ## Test mTLS configuration
	@echo "$(YELLOW)Testing mTLS configuration...$(NC)"
	@echo ""
	@echo "Testing Gateway health endpoint:"
	@curl -s http://localhost:8000/health || echo "$(RED)Gateway not responding$(NC)"
	@echo ""
	@echo "Testing Identity health through Gateway:"
	@curl -s http://localhost:8000/health/identity || echo "$(RED)Identity not responding$(NC)"
	@echo ""
	@echo "Testing Core health through Gateway:"
	@curl -s http://localhost:8000/health/core || echo "$(RED)Core not responding$(NC)"
	@echo ""
	@echo "$(GREEN)✅ mTLS test completed$(NC)"

# ============================================
# Database Management
# ============================================

prod-migrate: ## Run database migrations for all services (production)
	@echo "$(GREEN)Running production database migrations...$(NC)"
	@echo "$(YELLOW)  → Identity service...$(NC)"
	docker compose -f docker-compose.prod.yml --env-file .env.prod exec alfred-identity dotnet ./cli/Alfred.Identity.Cli.dll migrate
	@echo "$(YELLOW)  → Core service...$(NC)"
	docker compose -f docker-compose.prod.yml --env-file .env.prod exec alfred-core dotnet ./cli/Alfred.Core.Cli.dll migrate
	@echo "$(GREEN)✅ All migrations completed!$(NC)"

prod-seed: ## Seed database with initial data (production)
	@echo "$(GREEN)Seeding production database...$(NC)"
	@echo "$(YELLOW)  → Identity service...$(NC)"
	docker compose -f docker-compose.prod.yml --env-file .env.prod exec alfred-identity dotnet ./cli/Alfred.Identity.Cli.dll seed
	@echo "$(GREEN)✅ Seeding completed!$(NC)"

prod-init-db: ## Create databases for existing postgres (no volume reset needed)
	@echo "$(GREEN)Creating databases in existing postgres...$(NC)"
	docker compose -f docker-compose.prod.yml --env-file .env.prod exec postgres psql -U $${POSTGRES_USER:-postgres} -c "SELECT 'CREATE DATABASE alfred_identity' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'alfred_identity')\gexec" 2>/dev/null || true
	docker compose -f docker-compose.prod.yml --env-file .env.prod exec postgres psql -U $${POSTGRES_USER:-postgres} -c "SELECT 'CREATE DATABASE alfred_core' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'alfred_core')\gexec" 2>/dev/null || true
	docker compose -f docker-compose.prod.yml --env-file .env.prod exec postgres psql -U $${POSTGRES_USER:-postgres} -c "SELECT 'CREATE DATABASE alfred_notification' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'alfred_notification')\gexec" 2>/dev/null || true
	@echo "$(GREEN)✅ Databases ready!$(NC)"

prod-health: ## Check production services health
	@echo "$(GREEN)Checking production service health...$(NC)"
	@docker compose -f docker-compose.prod.yml --env-file .env.prod ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

migrate: ## Run all database migrations (production)
	@echo "$(GREEN)Running database migrations...$(NC)"
	docker compose -f docker-compose.prod.yml --env-file .env.prod exec alfred-identity dotnet ./cli/Alfred.Identity.Cli.dll migrate
	docker compose -f docker-compose.prod.yml --env-file .env.prod exec alfred-core dotnet ./cli/Alfred.Core.Cli.dll migrate
	@echo "$(GREEN)Migrations completed!$(NC)"

seed: ## Seed database with initial data (production)
	@echo "$(GREEN)Seeding production database...$(NC)"
	docker compose -f docker-compose.prod.yml --env-file .env.prod exec alfred-identity dotnet ./cli/Alfred.Identity.Cli.dll seed
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
prod-db-backup: ## Backup all Production DBs
	@echo "$(GREEN)Creating Production DB backups...$(NC)"
	@mkdir -p ./backups/prod
	@for db in alfred_identity alfred_core alfred_notification; do \
		echo "$(YELLOW)  → Backing up $$db...$(NC)"; \
		docker compose -f docker-compose.prod.yml --env-file .env.prod exec -T postgres sh -c "pg_dump -Fc -U \$$POSTGRES_USER $$db" > ./backups/prod/$$db-$(shell date +%Y%m%d-%H%M%S).dump; \
	done
	@echo "$(GREEN)✅ All backups created in ./backups/prod/$(NC)"

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

build: ## Build all production service images
	@echo "$(GREEN)Building all production service images...$(NC)"
	docker compose -f docker-compose.prod.yml --env-file .env.prod build --no-cache
	@echo "$(GREEN)Build completed!$(NC)"

ps: ## Show running containers
	@docker compose ps

shell-gateway: ## Shell into gateway container (production)
	docker compose -f docker-compose.prod.yml --env-file .env.prod exec alfred-gateway sh

shell-identity: ## Shell into identity container (production)
	docker compose -f docker-compose.prod.yml --env-file .env.prod exec alfred-identity sh

shell-core: ## Shell into core container (production)
	docker compose -f docker-compose.prod.yml --env-file .env.prod exec alfred-core sh

shell-notification: ## Shell into notification container (production)
	docker compose -f docker-compose.prod.yml --env-file .env.prod exec alfred-notification sh

shell-postgres: ## Shell into postgres container (dev)
	docker compose --env-file .env exec postgres psql -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-alfred_db}

shell-redis: ## Shell into redis container (dev)
	docker compose --env-file .env exec redis redis-cli

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
	docker compose -f docker-compose.prod.yml --env-file .env.prod down -v --remove-orphans 2>/dev/null || true
	docker volume rm alfred-postgres-data alfred-redis-data alfred-postgres-prod-data alfred-redis-prod-data 2>/dev/null || true
	docker image rm alfred-identity alfred-core alfred-notification alfred-gateway alfred-identity-web alfred-core-web 2>/dev/null || true
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

deploy-prod: prod-deploy ## Alias for prod-deploy (deprecated, use prod-deploy instead)
	@echo "$(YELLOW)Note: Use 'make prod-deploy' instead$(NC)"
