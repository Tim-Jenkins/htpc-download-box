# Deployment and management targets
.PHONY: setup deploy update status logs clean help

# Docker Compose command (supports both docker-compose and docker compose)
DOCKER_COMPOSE = ./docker-compose-wrapper.sh

# Default target
help:
	@echo "HTPC Download Box - Available commands:"
	@echo ""
	@echo "  setup     - Initial setup (create directories and .env)"
	@echo "  deploy    - Deploy the full stack"
	@echo "  update    - Update all containers to latest versions"
	@echo "  status    - Show status of all containers"
	@echo "  logs      - Show logs from all containers"
	@echo "  clean     - Stop containers and clean up Docker resources"
	@echo "  restart   - Restart all containers"
	@echo ""
	@echo "Service-specific commands:"
	@echo "  logs-<service>    - Show logs for specific service (e.g., logs-prowlarr)"
	@echo "  restart-<service> - Restart specific service (e.g., restart-plex)"

# Initial setup
setup:
	@echo "Setting up HTPC Download Box..."
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "Created .env file from template"; \
		echo "Please edit .env with your settings and run 'make deploy'"; \
		exit 1; \
	fi
	@echo "Configuration file exists. Run 'make deploy' to start deployment."

# Deploy the stack
deploy:
	@./deploy.sh

# Update all containers
update:
	@echo "Updating HTPC Download Box..."
	$(DOCKER_COMPOSE) down
	$(DOCKER_COMPOSE) pull
	$(DOCKER_COMPOSE) up -d
	@echo "Cleaning up unused images..."
	docker image prune -f
	@echo "Update complete!"

# Show container status
status:
	@echo "Container Status:"
	@$(DOCKER_COMPOSE) ps

# Show logs
logs:
	@echo "Showing logs from all containers (Ctrl+C to exit):"
	$(DOCKER_COMPOSE) logs -f

# Clean up everything
clean:
	@echo "Stopping all containers and cleaning up..."
	$(DOCKER_COMPOSE) down
	@echo "Removing unused Docker resources..."
	docker system prune -f
	@echo "Cleanup complete!"

# Restart all containers
restart:
	@echo "Restarting all containers..."
	$(DOCKER_COMPOSE) restart
	@echo "Restart complete!"

# Service-specific log commands
logs-deluge:
	$(DOCKER_COMPOSE) logs -f deluge

logs-prowlarr:
	$(DOCKER_COMPOSE) logs -f prowlarr

logs-sonarr:
	$(DOCKER_COMPOSE) logs -f sonarr

logs-radarr:
	$(DOCKER_COMPOSE) logs -f radarr

logs-plex:
	$(DOCKER_COMPOSE) logs -f plex-server

logs-bazarr:
	$(DOCKER_COMPOSE) logs -f bazarr

logs-overseerr:
	$(DOCKER_COMPOSE) logs -f overseerr

logs-traefik:
	$(DOCKER_COMPOSE) logs -f traefik

logs-dockerproxy:
	$(DOCKER_COMPOSE) logs -f dockerproxy

# Service-specific restart commands
restart-deluge:
	$(DOCKER_COMPOSE) restart deluge

restart-prowlarr:
	$(DOCKER_COMPOSE) restart prowlarr

restart-sonarr:
	$(DOCKER_COMPOSE) restart sonarr

restart-radarr:
	$(DOCKER_COMPOSE) restart radarr

restart-plex:
	$(DOCKER_COMPOSE) restart plex-server

restart-bazarr:
	$(DOCKER_COMPOSE) restart bazarr

restart-overseerr:
	$(DOCKER_COMPOSE) restart overseerr

restart-traefik:
	$(DOCKER_COMPOSE) restart traefik

restart-dockerproxy:
	$(DOCKER_COMPOSE) restart dockerproxy

# Legacy support
plex-update: update