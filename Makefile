# Deployment and management targets
.PHONY: setup deploy update status logs clean help

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
	docker-compose down
	docker-compose pull
	docker-compose up -d
	@echo "Cleaning up unused images..."
	docker image prune -f
	@echo "Update complete!"

# Show container status
status:
	@echo "Container Status:"
	@docker-compose ps

# Show logs
logs:
	@echo "Showing logs from all containers (Ctrl+C to exit):"
	docker-compose logs -f

# Clean up everything
clean:
	@echo "Stopping all containers and cleaning up..."
	docker-compose down
	@echo "Removing unused Docker resources..."
	docker system prune -f
	@echo "Cleanup complete!"

# Restart all containers
restart:
	@echo "Restarting all containers..."
	docker-compose restart
	@echo "Restart complete!"

# Service-specific log commands
logs-deluge:
	docker-compose logs -f deluge

logs-prowlarr:
	docker-compose logs -f prowlarr

logs-sonarr:
	docker-compose logs -f sonarr

logs-radarr:
	docker-compose logs -f radarr

logs-plex:
	docker-compose logs -f plex-server

logs-bazarr:
	docker-compose logs -f bazarr

logs-overseerr:
	docker-compose logs -f overseerr

logs-traefik:
	docker-compose logs -f traefik

logs-dockerproxy:
	docker-compose logs -f dockerproxy

# Service-specific restart commands
restart-deluge:
	docker-compose restart deluge

restart-prowlarr:
	docker-compose restart prowlarr

restart-sonarr:
	docker-compose restart sonarr

restart-radarr:
	docker-compose restart radarr

restart-plex:
	docker-compose restart plex-server

restart-bazarr:
	docker-compose restart bazarr

restart-overseerr:
	docker-compose restart overseerr

restart-traefik:
	docker-compose restart traefik

restart-dockerproxy:
	docker-compose restart dockerproxy

# Legacy support
plex-update: update