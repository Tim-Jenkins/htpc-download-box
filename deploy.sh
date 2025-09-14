#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root"
    exit 1
fi

print_status "Starting HTPC Download Box deployment..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if user is in docker group
if ! groups $USER | grep &>/dev/null '\bdocker\b'; then
    print_warning "User $USER is not in the docker group. You may need to run:"
    print_warning "sudo usermod -aG docker $USER"
    print_warning "Then log out and back in."
fi

# Check if .env exists
if [ ! -f .env ]; then
    print_warning ".env file not found. Copying from .env.example..."
    cp .env.example .env
    print_error "Please edit the .env file with your settings and run this script again."
    print_status "Key settings to configure:"
    print_status "  - ROOT: Directory where all data will be stored"
    print_status "  - PUID/PGID: Your user/group ID (run 'id \$USER' to get these)"
    print_status "  - TZ: Your timezone"
    exit 1
fi

# Source environment variables
source .env

# Validate required environment variables
if [ -z "$ROOT" ] || [ -z "$PUID" ] || [ -z "$PGID" ] || [ -z "$TZ" ]; then
    print_error "Missing required environment variables in .env file"
    print_status "Please ensure ROOT, PUID, PGID, and TZ are all set"
    exit 1
fi

print_status "Using configuration:"
print_status "  ROOT: $ROOT"
print_status "  PUID: $PUID"
print_status "  PGID: $PGID"
print_status "  TZ: $TZ"

# Create directory structure
print_status "Creating directory structure at ${ROOT}..."
directories=(
    "${ROOT}/config/deluge"
    "${ROOT}/config/prowlarr"
    "${ROOT}/config/sonarr"
    "${ROOT}/config/radarr"
    "${ROOT}/config/plex/db"
    "${ROOT}/config/plex/transcode"
    "${ROOT}/config/bazarr"
    "${ROOT}/config/overseerr"
    "${ROOT}/config/traefik"
    "${ROOT}/downloads"
    "${ROOT}/complete/movies"
    "${ROOT}/complete/tv"
)

for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_status "Created: $dir"
    fi
done

# Set ownership
print_status "Setting ownership of ${ROOT} to ${PUID}:${PGID}..."
if [ -w "$ROOT" ]; then
    chown -R ${PUID}:${PGID} ${ROOT}
else
    sudo chown -R ${PUID}:${PGID} ${ROOT}
fi

# Determine which docker compose command to use
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
elif docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    print_error "Neither docker-compose nor docker compose found"
    exit 1
fi

# Validate Docker Compose file
print_status "Validating Docker Compose configuration..."
$DOCKER_COMPOSE config > /dev/null
if [ $? -eq 0 ]; then
    print_success "Docker Compose configuration is valid"
else
    print_error "Docker Compose configuration is invalid"
    exit 1
fi

# Pull latest images
print_status "Pulling latest Docker images..."
$DOCKER_COMPOSE pull

# Deploy stack
print_status "Deploying HTPC Download Box stack..."
$DOCKER_COMPOSE up -d

# Wait a moment for containers to start
sleep 5

# Show status
print_status "Checking container status..."
$DOCKER_COMPOSE ps

# Check if all containers are running
failed_containers=$($DOCKER_COMPOSE ps --services --filter "status=exited")
if [ -n "$failed_containers" ]; then
    print_error "Some containers failed to start:"
    echo "$failed_containers"
    print_status "Check logs with: $DOCKER_COMPOSE logs [service-name]"
else
    print_success "All containers are running!"
fi

print_success "Deployment complete!"
print_status ""
print_status "Web interfaces are now available via Traefik reverse proxy:"
print_status "  Traefik Dashboard: http://$(hostname -I | awk '{print $1}'):8080"
print_status "  Main Access Point: http://$(hostname -I | awk '{print $1}')/"
print_status ""
print_status "Service URLs:"
print_status "  Prowlarr:  http://$(hostname -I | awk '{print $1}')/prowlarr (via Traefik)"
print_status "  Sonarr:    http://$(hostname -I | awk '{print $1}')/sonarr (via Traefik)"
print_status "  Radarr:    http://$(hostname -I | awk '{print $1}')/radarr (via Traefik)"
print_status "  Plex:      http://$(hostname -I | awk '{print $1}'):32400 (direct access)"
print_status "  Deluge:    http://$(hostname -I | awk '{print $1}')/deluge (via Traefik)"
print_status "  Bazarr:    http://$(hostname -I | awk '{print $1}')/bazarr (via Traefik)"
print_status "  Overseerr: http://$(hostname -I | awk '{print $1}')/overseerr (via Traefik)"
print_status ""
print_status "Use 'make logs' to view container logs"
print_status "Use 'make status' to check container status"
print_status "Use 'make update' to update all containers"