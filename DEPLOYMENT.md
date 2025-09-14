# HTPC Download Box Deployment Guide

This guide covers deploying the HTPC Download Box stack on your Raspberry Pi or other Linux system.

## Quick Start

### 1. SSH to Your System
```bash
ssh pi@your-raspberry-pi-ip
```

### 2. Clone the Repository
```bash
git clone https://github.com/your-username/htpc-download-box.git
cd htpc-download-box
```

### 3. Configure Environment
```bash
# Copy the example configuration
cp .env.example .env

# Edit the configuration file
nano .env
```

**Required Settings in `.env`:**
```bash
# Your timezone (see: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
TZ=America/New_York

# Your user/group ID (run 'id $USER' to get these values)
PUID=1000
PGID=1000

# Root directory where all data will be stored
ROOT=/media/htpc
```

### 4. Deploy the Stack
```bash
# Option 1: Use the automated deployment script
./deploy.sh

# Option 2: Use Make
make deploy
```

## Directory Structure

The deployment will create the following structure at your configured `ROOT` path:

```
${ROOT}/                    # Your configured root directory
├── config/                 # Application configurations
│   ├── deluge/            # Deluge torrent client config
│   ├── prowlarr/          # Prowlarr indexer manager config
│   ├── sonarr/            # Sonarr TV show manager config
│   ├── radarr/            # Radarr movie manager config
│   ├── plex/              # Plex media server config
│   │   ├── db/            # Plex database
│   │   └── transcode/     # Temporary transcoding files
│   ├── bazarr/            # Bazarr subtitle manager config
│   ├── overseerr/         # Overseerr request manager config
│   └── traefik/           # Traefik reverse proxy config
├── downloads/              # Active downloads directory
└── complete/               # Completed media library
    ├── movies/            # Movies library for Plex
    └── tv/                # TV shows library for Plex
```

## Management Commands

The project includes a comprehensive Makefile for easy management:

### Basic Commands
```bash
make help         # Show all available commands
make setup        # Initial setup (create .env from template)
make deploy       # Deploy the full stack
make status       # Show container status
make logs         # Show logs from all containers
make update       # Update all containers to latest versions
make restart      # Restart all containers
make clean        # Stop containers and clean up resources
```

### Service-Specific Commands
```bash
# View logs for specific services
make logs-prowlarr
make logs-sonarr
make logs-radarr
make logs-plex
make logs-deluge
make logs-bazarr
make logs-overseerr

# Restart specific services
make restart-prowlarr
make restart-sonarr
make restart-radarr
make restart-plex
make restart-deluge
make restart-bazarr
make restart-overseerr
```

## Web Interfaces

After deployment, all services are accessible through Traefik reverse proxy with path-based routing:

| Service   | URL | Description |
|-----------|-----|-------------|
| **Traefik Dashboard** | `http://your-ip:8080` | Reverse proxy dashboard and monitoring |
| **Main Access Point** | `http://your-ip/` | Single entry point for most services |
| Prowlarr  | `http://your-ip/prowlarr` | Indexer manager for torrents and usenet |
| Sonarr    | `http://your-ip/sonarr` | TV show management and automation |
| Radarr    | `http://your-ip/radarr` | Movie management and automation |
| **Plex**  | `http://your-ip:32400` | **Media server (direct access)** |
| Deluge    | `http://your-ip/deluge` | Torrent download client |
| Bazarr    | `http://your-ip/bazarr` | Subtitle management |
| Overseerr | `http://your-ip/overseerr` | Media request management |

### Key Advantages:
- **Reduced Ports**: Only 3 ports exposed (80, 8080, 32400) instead of 7+ ports
- **Clean URLs**: Path-based routing with meaningful service names for most services
- **Enhanced Security**: Container network isolation for all services except Plex
- **Plex Optimization**: Full DLNA, remote access, and discovery functionality
- **Health Monitoring**: Built-in health checks for all services
- **Future Ready**: Easy to add SSL certificates or authentication

### Network Architecture:
- **Plex**: Host networking for full functionality (DLNA, remote access)
- **Other Services**: Isolated bridge networks via Traefik reverse proxy

## Auto-Updates with Watchtower

The stack includes Watchtower for automatic container updates:

- **Schedule**: Daily at 2:00 AM
- **Cleanup**: Automatically removes old Docker images
- **Safe Updates**: Only updates running containers, skips stopped ones

### Watchtower Configuration

To modify the update schedule, edit the `WATCHTOWER_SCHEDULE` environment variable in docker-compose.yml:

```yaml
environment:
  - WATCHTOWER_SCHEDULE=0 2 * * *  # Cron format: minute hour day month weekday
```

Examples:
- `0 2 * * *` - Daily at 2:00 AM
- `0 2 * * 0` - Weekly on Sunday at 2:00 AM
- `0 2 1 * *` - Monthly on the 1st at 2:00 AM

## Troubleshooting

### Container Won't Start
```bash
# Check container status
make status

# View logs for specific service
make logs-[service-name]

# Restart a specific service
make restart-[service-name]
```

### Permission Issues
```bash
# Check your PUID and PGID
id $USER

# Update .env file with correct values
nano .env

# Redeploy
make deploy
```

### Storage Issues
```bash
# Check available disk space
df -h

# Check directory permissions
ls -la ${ROOT}

# Fix ownership if needed
sudo chown -R ${PUID}:${PGID} ${ROOT}
```

### Network Issues
```bash
# Check if Traefik ports are available
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :8080

# Check Docker networks
docker network ls

# Test service connectivity
curl -f http://localhost/prowlarr
curl -f http://localhost:8080  # Traefik dashboard
```

### Traefik Issues
```bash
# Check Traefik logs
make logs-traefik

# Verify Traefik configuration
docker exec traefik traefik version

# Check service discovery
docker exec traefik cat /etc/traefik/traefik.yml
```

## Updating the Stack

### Manual Update
```bash
make update
```

### Automatic Updates
Watchtower handles automatic updates, but you can also:

```bash
# Update only specific services
docker-compose pull prowlarr sonarr radarr
docker-compose up -d prowlarr sonarr radarr
```

## Backup and Restore

### Backup Configuration
```bash
# Backup all configurations
tar -czf htpc-backup-$(date +%Y%m%d).tar.gz ${ROOT}/config

# Backup specific service config
tar -czf plex-backup-$(date +%Y%m%d).tar.gz ${ROOT}/config/plex
```

### Restore Configuration
```bash
# Stop containers
make clean

# Restore backup
tar -xzf htpc-backup-YYYYMMDD.tar.gz -C /

# Restart containers
make deploy
```

## Security Considerations

1. **Firewall**: Consider using a firewall to restrict access to web interfaces
2. **VPN**: For additional security, consider routing torrent traffic through a VPN
3. **Updates**: Watchtower keeps containers updated with security patches
4. **Access**: Limit SSH access and use key-based authentication

## Getting Help

- Check container logs: `make logs-[service]`
- Review Docker Compose configuration: `docker-compose config`
- Validate environment: `cat .env`
- Check system resources: `htop` or `docker stats`

For service-specific issues, consult the official documentation:
- [Prowlarr Wiki](https://wiki.servarr.com/prowlarr)
- [Sonarr Wiki](https://wiki.servarr.com/sonarr)
- [Radarr Wiki](https://wiki.servarr.com/radarr)
- [Plex Support](https://support.plex.tv/)