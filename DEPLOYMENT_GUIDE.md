# Deployment Guide for Restructured Docker MCP Gateway

## Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Sufficient disk space for data persistence
- Network access for external services
- (Optional) Squid proxy for VPN scenarios

### Initial Setup

1. **Clone or navigate to your project directory**
   ```bash
   cd e:/DOCKER_MCP_GATE_WAY
   ```

2. **Copy environment template**
   ```bash
   cp .env.example .env
   ```

3. **Edit environment variables**
   ```bash
   # Edit .env file with your specific configurations
   notepad .env
   ```

4. **Create necessary directories**
   ```bash
   mkdir -p data/mcp data/kaggle data/playwright logs backups
   ```

## Service Profiles

### Available Profiles

| Profile | Services Included | Use Case |
|---------|------------------|----------|
| `all` | All services | Full production deployment |
| `core` | MCP Gateway only | Minimal setup, API only |
| `data` | Kaggle + MSSQL bridges | Data science and database access |
| `ai` | Context7 + Gistpad bridges | AI/ML and GitHub integration |
| `browser` | Playwright bridge | Web automation and scraping |
| `minimal` | Core + essential services | Lightweight production setup |

### Starting Services

#### Start All Services
```bash
docker-compose --profile all up -d
```

#### Start Specific Profile
```bash
# Start only browser services
docker-compose --profile browser up -d

# Start data services
docker-compose --profile data up -d

# Start AI services
docker-compose --profile ai up -d

# Start core gateway only
docker-compose --profile core up -d
```

#### Start Multiple Profiles
```bash
# Start core + data services
docker-compose --profile core --profile data up -d

# Start AI + browser services
docker-compose --profile ai --profile browser up -d
```

### Managing Services

#### View Status
```bash
# View all running services
docker-compose ps

# View services for specific profile
docker-compose --profile data ps
```

#### View Logs
```bash
# View all logs
docker-compose logs -f

# View logs for specific service
docker-compose logs -f mcp-gateway

# View logs for profile services
docker-compose --profile ai logs -f
```

#### Stop Services
```bash
# Stop all services
docker-compose down

# Stop specific profile services
docker-compose --profile data down

# Stop and remove volumes (WARNING: This deletes data)
docker-compose down -v
```

## Configuration

### Environment Variables

Key environment variables to configure in `.env`:

#### Security Configuration
```bash
JWT_SECRET_KEY=your-super-secret-jwt-key-change-in-production
BASIC_AUTH_USER=admin
BASIC_AUTH_PASSWORD=your-secure-password
AUTH_REQUIRED=true
```

#### External Service Configuration
```bash
# Kaggle
KAGGLE_USERNAME=your-kaggle-username
KAGGLE_KEY=your-kaggle-api-key

# SQL Server
MSSQL_SERVER=host.docker.internal
MSSQL_DATABASE=your-database
MSSQL_USER=your-username
MSSQL_PASSWORD=your-password

# Context7
CONTEXT7_API_KEY=your-context7-api-key

# GitHub
GITHUB_TOKEN=your-github-personal-access-token
```

#### Performance Configuration
```bash
# Memory limits (adjust based on your system)
MCP_GATEWAY_MEMORY_LIMIT=512m
PLAYWRIGHT_BRIDGE_MEMORY_LIMIT=1g

# CPU limits
MCP_GATEWAY_CPU_LIMIT=0.5
PLAYWRIGHT_BRIDGE_CPU_LIMIT=1.0
```

### Network Configuration

#### Default Network Setup
- Network name: `mcpnet`
- Subnet: `172.20.0.0/16`
- All services communicate within this network

#### Custom Network Configuration
```bash
# In .env file
NETWORK_NAME=my-mcp-network
NETWORK_SUBNET=192.168.100.0/24
```

### Proxy Configuration (for VPN/Corporate Networks)

#### Squid Proxy Setup
1. Install Squid proxy on Windows
2. Configure `squid.conf` (see README.md for details)
3. Update `.env` with proxy settings:
```bash
PROXY_SERVER=http://host.docker.internal:3128
PROXY_BYPASS=localhost,127.0.0.1,mcp-gateway,playwright-bridge,kaggle-bridge,gistpad-bridge,context7-bridge,mssql-bridge,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
```

#### Test Proxy Configuration
```bash
docker exec -it playwright-bridge bash -lc "curl -s -x http://host.docker.internal:3128 http://ifconfig.io/ip && echo"
```

## Data Persistence

### Data Directories
- `data/mcp/`: MCP Gateway SQLite database and persistent data
- `data/kaggle/`: Kaggle datasets and cache
- `data/playwright/`: Playwright outputs (screenshots, videos, traces)

### Backup Strategy
```bash
# Create backup script
mkdir -p scripts/backup
```

Create `scripts/backup/backup.sh`:
```bash
#!/bin/bash
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup MCP data
tar -czf "$BACKUP_DIR/mcp_data_$DATE.tar.gz" data/mcp/

# Backup Kaggle data
tar -czf "$BACKUP_DIR/kaggle_data_$DATE.tar.gz" data/kaggle/

# Backup environment file
cp .env "$BACKUP_DIR/env_$DATE.backup"

echo "Backup completed: $BACKUP_DIR"
```

## Monitoring and Health Checks

### Health Check Status
```bash
# Check health of all services
docker-compose ps

# Check detailed health
docker inspect mcp-gateway | grep -A 10 Health
```

### Service Endpoints
- MCP Gateway UI: `http://localhost:4444`
- Kaggle Bridge: `http://localhost:9000/sse` (internal)
- MSSQL Bridge: `http://localhost:9020/sse` (internal)
- Context7 Bridge: `http://localhost:9030/sse` (internal)
- Gistpad Bridge: `http://localhost:9010/sse` (internal)
- Playwright Bridge: `http://localhost:9040/sse` (internal)

### Log Monitoring
```bash
# Real-time log monitoring
docker-compose logs -f --tail=100

# Monitor specific service
docker-compose logs -f --tail=50 mcp-gateway

# Filter logs by level (if configured)
docker-compose logs mcp-gateway | grep ERROR
```

## Troubleshooting

### Common Issues

#### Services Won't Start
```bash
# Check Docker daemon
docker info

# Check compose file syntax
docker-compose config

# Check port conflicts
netstat -ano | findstr :4444
```

#### Network Issues
```bash
# Check network configuration
docker network ls
docker network inspect mcpnet

# Test service connectivity
docker exec -it mcp-gateway ping kaggle-bridge
```

#### Permission Issues
```bash
# Check directory permissions
ls -la data/

# Fix permissions (Linux/WSL)
sudo chown -R $USER:$USER data/
chmod -R 755 data/
```

#### Proxy Issues
```bash
# Test proxy from container
docker exec -it mcp-gateway curl -x http://host.docker.internal:3128 http://google.com

# Check proxy environment variables
docker exec -it mcp-gateway env | grep -i proxy
```

### Performance Optimization

#### Memory Usage
```bash
# Monitor memory usage
docker stats

# Check memory limits
docker inspect mcp-gateway | grep -A 5 Memory
```

#### Disk Space
```bash
# Check disk usage
docker system df

# Clean up unused images
docker image prune -f

# Clean up unused volumes (WARNING: This deletes data)
docker volume prune -f
```

## Production Deployment

### Security Considerations
1. Change all default passwords and secrets
2. Use HTTPS in production (reverse proxy)
3. Implement proper firewall rules
4. Regular security updates
5. Monitor access logs

### Scaling Considerations
1. Monitor resource usage
2. Adjust memory/CPU limits as needed
3. Consider external database for production
4. Implement load balancing for high availability
5. Set up proper backup and recovery procedures

### Maintenance Tasks
1. Regular backup of data directories
2. Update container images
3. Monitor health checks
4. Review and rotate secrets
5. Clean up old logs and temporary files

## Migration from Old Structure

### Backup Existing Setup
```bash
# Stop existing services
docker-compose down

# Backup current data
cp -r data data_backup_$(date +%Y%m%d)
cp docker-compose.yml docker-compose.yml.backup
cp .env .env.backup
```

### Deploy New Structure
```bash
# Deploy new structure (this will be implemented in Code mode)
# Follow the implementation steps from the restructuring plan
```

### Verification
```bash
# Test all profiles
docker-compose --profile core up -d
docker-compose --profile data up -d
docker-compose --profile ai up -d
docker-compose --profile browser up -d

# Verify service connectivity
docker-compose ps
docker-compose logs -f
```

This deployment guide provides comprehensive instructions for deploying, managing, and troubleshooting the restructured Docker MCP Gateway in production environments.