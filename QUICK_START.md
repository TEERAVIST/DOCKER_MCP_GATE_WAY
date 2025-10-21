# Quick Start Guide

## 🚀 Get Your MCP Gateway Running in 5 Minutes

### 1. Setup Environment
```bash
# Copy the environment template
copy .env.example .env

# Edit with your configuration
notepad .env
```

### 2. Configure Required Settings

Edit `.env` and set these **essential variables**:

#### Security (Required)
```bash
JWT_SECRET_KEY=your-super-secret-jwt-key-CHANGE-THIS
BASIC_AUTH_USER=admin
BASIC_AUTH_PASSWORD=your-secure-password-CHANGE-THIS
PLATFORM_ADMIN_EMAIL=admin@yourdomain.com
PLATFORM_ADMIN_PASSWORD=your-secure-password-CHANGE-THIS
```

#### External Services (Configure as needed)
```bash
# Kaggle (for data operations)
KAGGLE_USERNAME=your-kaggle-username
KAGGLE_KEY=your-kaggle-api-key

# SQL Server (for database operations)
MSSQL_SERVER=host.docker.internal
MSSQL_DATABASE=your-database-name
MSSQL_USER=your-username
MSSQL_PASSWORD=your-password

# Context7 (for AI/ML operations)
CONTEXT7_API_KEY=your-context7-api-key

# GitHub (for Gistpad operations)
GITHUB_TOKEN=ghp_your-github-personal-access-token
```

### 3. Start Services

#### Start Core Gateway Only
```bash
docker-compose -f docker-compose.new.yml --profile core up -d
```

#### Start All Services
```bash
docker-compose -f docker-compose.new.yml --profile all up -d
```

#### Start Specific Service Groups
```bash
# Data services (Kaggle, MSSQL)
docker-compose -f docker-compose.new.yml --profile data up -d

# AI/ML services (Context7, Gistpad)
docker-compose -f docker-compose.new.yml --profile ai up -d

# Browser automation (Playwright)
docker-compose -f docker-compose.new.yml --profile browser up -d
```

### 4. Access Your MCP Gateway

Open your browser and navigate to:
```
http://localhost:4444
```

Login with:
- **Username**: `admin` (or your `BASIC_AUTH_USER`)
- **Password**: Your `BASIC_AUTH_PASSWORD`

### 5. Verify Everything Works

```bash
# Check running services
docker-compose -f docker-compose.new.yml ps

# Check health status
monitoring\health-checks\health-check.bat

# View logs
docker-compose -f docker-compose.new.yml logs -f
```

## 📋 Available Profiles

| Profile | Services | Command |
|---------|----------|---------|
| `core` | MCP Gateway only | `docker-compose -f docker-compose.new.yml --profile core up -d` |
| `data` | Kaggle + MSSQL | `docker-compose -f docker-compose.new.yml --profile data up -d` |
| `ai` | Context7 + Gistpad | `docker-compose -f docker-compose.new.yml --profile ai up -d` |
| `browser` | Playwright | `docker-compose -f docker-compose.new.yml --profile browser up -d` |
| `all` | All services | `docker-compose -f docker-compose.new.yml --profile all up -d` |

## 🔧 Common Commands

### Service Management
```bash
# Stop services
docker-compose -f docker-compose.new.yml down

# Restart services
docker-compose -f docker-compose.new.yml restart

# View logs for specific service
docker-compose -f docker-compose.new.yml logs -f mcp-gateway
```

### Backup
```bash
# Create backup
scripts\backup\backup.bat
```

### Health Check
```bash
# Run health monitoring
monitoring\health-checks\health-check.bat
```

## ⚠️ Important Security Notes

1. **Change all default passwords** before production use
2. **Use strong JWT secrets** (minimum 32 characters)
3. **Configure firewall** to restrict access to port 4444
4. **Use HTTPS** in production (configure reverse proxy)
5. **Regularly update** container images

## 🐛 Troubleshooting

### Services won't start
```bash
# Check Docker daemon
docker info

# Check configuration
docker-compose -f docker-compose.new.yml config

# Check logs
docker-compose -f docker-compose.new.yml logs
```

### Can't access Gateway
```bash
# Check if port is in use
netstat -ano | findstr :4444

# Check Gateway logs
docker-compose -f docker-compose.new.yml logs mcp-gateway
```

### Proxy Issues
If you're behind a corporate proxy, configure these in `.env`:
```bash
PROXY_SERVER=http://host.docker.internal:3128
PROXY_BYPASS=localhost,127.0.0.1,mcp-gateway,playwright-bridge,kaggle-bridge,gistpad-bridge,context7-bridge,mssql-bridge
```

## 📚 More Information

- **[README.NEW_STRUCTURE.md](README.NEW_STRUCTURE.md)** - Complete documentation
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Production deployment guide
- **[TECHNICAL_SPECIFICATION.md](TECHNICAL_SPECIFICATION.md)** - Technical details

## 🎉 You're Ready!

Your MCP Gateway is now running with the new modular structure! 

**Next steps:**
1. Explore the MCP Gateway UI at `http://localhost:4444`
2. Configure your external service credentials
3. Start additional service profiles as needed
4. Set up regular backups
5. Configure monitoring and alerts

Enjoy your new production-ready MCP Gateway! 🚀