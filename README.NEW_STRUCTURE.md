# MCP Gateway - New Modular Structure

Your Docker MCP Gateway has been successfully restructured for production use!

## 🎯 What's New

### Modular Architecture
- **Separated services** into logical groups (core, data, ai, browser)
- **Profile-based startup** for selective service management
- **Production-ready configuration** with enhanced security and monitoring
- **Comprehensive documentation** and automation scripts

### New Directory Structure
```
e:/DOCKER_MCP_GATE_WAY/
├── docker-compose.new.yml          # Main orchestrator
├── .env.production                  # Production environment template
├── compose/                         # Modular compose files
│   ├── compose.core.yml            # Core MCP Gateway
│   ├── compose.net.yml             # Networking configuration
│   ├── compose.data.yml            # Data services (Kaggle, MSSQL)
│   ├── compose.ai.yml              # AI/ML services (Context7, Gistpad)
│   └── compose.browser.yml         # Browser automation (Playwright)
├── scripts/                         # Automation scripts
│   ├── init/migrate-to-new-structure.bat
│   ├── backup/backup.bat & backup.sh
│   └── maintenance/
├── monitoring/                      # Health checks and metrics
│   └── health-checks/health-check.bat
├── config/                          # Configuration files
├── logs/                           # Persistent logs
└── docs/                           # Documentation
```

## 🚀 Quick Start

### 1. Migration (if upgrading from old structure)
```bash
# Run the migration script
scripts\init\migrate-to-new-structure.bat
```

### 2. Setup Environment
```bash
# Copy production environment template
copy .env.production .env

# Edit with your configuration
notepad .env
```

### 3. Start Services

#### Start all services
```bash
docker-compose -f docker-compose.new.yml --profile all up -d
```

#### Start specific service groups
```bash
# Core gateway only
docker-compose -f docker-compose.new.yml --profile core up -d

# Data services (Kaggle, MSSQL)
docker-compose -f docker-compose.new.yml --profile data up -d

# AI/ML services (Context7, Gistpad)
docker-compose -f docker-compose.new.yml --profile ai up -d

# Browser automation (Playwright)
docker-compose -f docker-compose.new.yml --profile browser up -d

# Minimal setup
docker-compose -f docker-compose.new.yml --profile minimal up -d
```

## 📋 Available Profiles

| Profile | Services | Use Case |
|---------|----------|----------|
| `all` | All services | Full production deployment |
| `core` | MCP Gateway only | API-only setup |
| `data` | Kaggle + MSSQL bridges | Data science & database access |
| `ai` | Context7 + Gistpad bridges | AI/ML & GitHub integration |
| `browser` | Playwright bridge | Web automation & scraping |
| `minimal` | Core + essentials | Lightweight production setup |

## 🛠️ Management Commands

### Service Management
```bash
# View running services
docker-compose -f docker-compose.new.yml ps

# View logs
docker-compose -f docker-compose.new.yml logs -f

# View logs for specific service
docker-compose -f docker-compose.new.yml logs -f mcp-gateway

# Stop services
docker-compose -f docker-compose.new.yml down

# Stop specific profile
docker-compose -f docker-compose.new.yml --profile data down
```

### Health Monitoring
```bash
# Run comprehensive health check
monitoring\health-checks\health-check.bat
```

### Backup Management
```bash
# Create backup
scripts\backup\backup.bat

# List backups
dir backups\
```

## 🔧 Configuration

### Key Environment Variables
Edit `.env` file with your specific settings:

#### Security (REQUIRED)
```bash
JWT_SECRET_KEY=your-super-secret-jwt-key-CHANGE-IN-PRODUCTION
BASIC_AUTH_USER=admin
BASIC_AUTH_PASSWORD=CHANGE-THIS-PASSWORD-IN-PRODUCTION
```

#### External Services
```bash
KAGGLE_USERNAME=your-kaggle-username
KAGGLE_KEY=your-kaggle-api-key
CONTEXT7_API_KEY=your-context7-api-key
GITHUB_TOKEN=your-github-personal-access-token
MSSQL_SERVER=host.docker.internal
MSSQL_DATABASE=your-database
MSSQL_USER=your-username
MSSQL_PASSWORD=your-password
```

#### Performance Tuning
```bash
MCP_GATEWAY_MEMORY_LIMIT=512m
PLAYWRIGHT_BRIDGE_MEMORY_LIMIT=1g
SHM_SIZE=1g
```

## 🌐 Service Endpoints

- **MCP Gateway UI**: `http://localhost:4444`
- **Kaggle Bridge**: `http://localhost:9000/sse` (internal)
- **MSSQL Bridge**: `http://localhost:9020/sse` (internal)
- **Context7 Bridge**: `http://localhost:9030/sse` (internal)
- **Gistpad Bridge**: `http://localhost:9010/sse` (internal)
- **Playwright Bridge**: `http://localhost:9040/sse` (internal)

## 🔒 Security Features

- **JWT authentication** with configurable secrets
- **Basic authentication** for admin access
- **Network isolation** via dedicated Docker network
- **Resource limits** per service
- **Non-root container users**
- **Proxy support** for corporate networks

## 📊 Monitoring & Logging

- **Structured logging** with rotation
- **Health checks** for all services
- **Resource monitoring** with limits
- **Automated backup** system
- **Performance metrics** collection

## 🔄 Migration from Old Structure

The migration script automatically:
1. **Backs up** your current setup
2. **Creates** new directory structure
3. **Migrates** configuration files
4. **Preserves** existing data
5. **Provides rollback** instructions

### Manual Migration Steps
1. Run: `scripts\init\migrate-to-new-structure.bat`
2. Edit: `.env` with your configuration
3. Test: `docker-compose -f docker-compose.new.yml --profile core up -d`
4. Verify: Access `http://localhost:4444`
5. Start additional profiles as needed

## 🐛 Troubleshooting

### Common Issues

#### Services won't start
```bash
# Check Docker daemon
docker info

# Check compose configuration
docker-compose -f docker-compose.new.yml config

# Check environment variables
docker-compose -f docker-compose.new.yml config
```

#### Network issues
```bash
# Check network
docker network ls
docker network inspect mcpnet

# Test connectivity
docker exec -it mcp-gateway ping kaggle-bridge
```

#### Permission issues
```bash
# Check directory permissions
dir data\

# Fix permissions (if needed)
icacls data /grant Everyone:F /T
```

## 📚 Documentation

- **[RESTRUCTURING_PLAN.md](RESTRUCTURING_PLAN.md)** - Overall restructuring strategy
- **[TECHNICAL_SPECIFICATION.md](TECHNICAL_SPECIFICATION.md)** - Detailed technical specifications
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Comprehensive deployment guide
- **[ARCHITECTURE_DIAGRAM.md](ARCHITECTURE_DIAGRAM.md)** - System architecture diagrams

## 🎉 Benefits of New Structure

✅ **Modularity**: Easy to manage individual service groups  
✅ **Scalability**: Better resource management and scaling  
✅ **Maintainability**: Clear separation of concerns  
✅ **Production Ready**: Enhanced security and monitoring  
✅ **Flexibility**: Selective service startup via profiles  
✅ **Organization**: Better file and directory structure  
✅ **Automation**: Comprehensive scripts for backup and health checks  

## 🆘 Support

If you encounter issues:
1. Check the health check: `monitoring\health-checks\health-check.bat`
2. Review logs: `docker-compose -f docker-compose.new.yml logs`
3. Consult documentation in the `docs/` directory
4. Check the troubleshooting guide in [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

---

**Your MCP Gateway is now ready for production with the new modular structure! 🚀**