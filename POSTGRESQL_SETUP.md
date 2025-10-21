# PostgreSQL Setup Guide for MCP Gateway

This guide will help you set up PostgreSQL as the production database for your MCP Gateway, replacing SQLite for better performance and scalability.

## 🎯 Why PostgreSQL?

- **Production Ready**: Enterprise-grade database with ACID compliance
- **Better Performance**: Optimized for concurrent connections and complex queries
- **Scalability**: Handles large datasets and high traffic loads
- **Advanced Features**: Full-text search, JSON support, advanced indexing
- **Security**: Robust authentication and authorization mechanisms
- **Backup & Recovery**: Point-in-time recovery and streaming replication

## 📋 Prerequisites

1. **Docker and Docker Compose** installed and running
2. **Sufficient disk space** (minimum 2GB for PostgreSQL data)
3. **Network access** to pull Docker images (may need proxy configuration)
4. **Administrator privileges** to run Docker commands

## 🚀 Quick Setup

### 1. Update Environment Configuration

Edit your `.env` file and set secure PostgreSQL passwords:

```bash
# PostgreSQL Configuration
POSTGRES_DB=mcp_gateway
POSTGRES_USER=mcp_user
POSTGRES_PASSWORD=your-secure-postgres-password-CHANGE-THIS
POSTGRES_PORT=5432

# PgAdmin Configuration (Optional)
PGADMIN_DEFAULT_EMAIL=admin@mcp.local
PGADMIN_DEFAULT_PASSWORD=your-secure-pgadmin-password-CHANGE-THIS
PGADMIN_PORT=5050
```

### 2. Start PostgreSQL Database

```bash
# Start only database services
docker-compose -f docker-compose.new.yml --profile database up -d

# Or start database with core services
docker-compose -f docker-compose.new.yml --profile core up -d
```

### 3. Verify PostgreSQL Setup

```bash
# Check if PostgreSQL is running
docker-compose -f docker-compose.new.yml ps postgres

# Test database connection
docker exec mcp-postgres psql -U mcp_user -d mcp_gateway -c "SELECT version();"

# Check database schema
docker exec mcp-postgres psql -U mcp_user -d mcp_gateway -c "\dt"
```

### 4. Start MCP Gateway

```bash
# Start MCP Gateway with PostgreSQL
docker-compose -f docker-compose.new.yml --profile core up -d

# Check Gateway logs
docker-compose -f docker-compose.new.yml logs mcp-gateway
```

### 5. Access Your MCP Gateway

Open your browser and navigate to:
```
http://localhost:4444
```

## 🔧 Advanced Configuration

### Database Performance Tuning

Edit `config/postgres/init/01-init-database.sql` to add performance optimizations:

```sql
-- Memory settings
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET work_mem = '4MB';

-- Connection settings
ALTER SYSTEM SET max_connections = '100';
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';

-- Logging settings
ALTER SYSTEM SET log_min_duration_statement = '1000';
ALTER SYSTEM SET log_checkpoints = 'on';
```

### PgAdmin Setup (Optional)

Access PgAdmin web interface:
```
http://localhost:5050
```

**Login Credentials:**
- Email: `admin@mcp.local`
- Password: Your PGAdmin password from `.env`

**Server Connection:**
- Host: `postgres`
- Port: `5432`
- Database: `mcp_gateway`
- Username: `mcp_user`
- Password: Your PostgreSQL password from `.env`

### Database Backup and Recovery

#### Manual Backup
```bash
# Create backup
docker exec mcp-postgres pg_dump -U mcp_user mcp_gateway > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore backup
docker exec -i mcp-postgres psql -U mcp_user mcp_gateway < backup_file.sql
```

#### Automated Backup
```bash
# Use the backup script
scripts\backup\backup.bat

# Or create a scheduled task
schtasks /create /tn "MCP_PostgreSQL_Backup" /tr "scripts\backup\backup.bat" /sc daily /st 02:00
```

## 🔄 Migration from SQLite

### Automated Migration

Use the provided migration script:

```bash
# Run the migration script
scripts\init\migrate-to-postgresql.bat
```

This script will:
1. **Backup** your current SQLite data
2. **Start** PostgreSQL database service
3. **Create** PostgreSQL database schema
4. **Update** configuration to use PostgreSQL
5. **Provide** rollback instructions

### Manual Migration Steps

1. **Stop existing services:**
   ```bash
   docker-compose -f docker-compose.new.yml down
   ```

2. **Backup SQLite data:**
   ```bash
   mkdir backup
   copy data\mcp\mcp.db backup\
   ```

3. **Start PostgreSQL:**
   ```bash
   docker-compose -f docker-compose.new.yml --profile database up -d
   ```

4. **Update .env file:**
   ```bash
   DATABASE_URL=postgresql://mcp_user:your-password@postgres:5432/mcp_gateway
   ```

5. **Start MCP Gateway:**
   ```bash
   docker-compose -f docker-compose.new.yml --profile core up -d
   ```

## 🐛 Troubleshooting

### Common Issues

#### PostgreSQL Won't Start
```bash
# Check logs
docker-compose -f docker-compose.new.yml logs postgres

# Check if port is in use
netstat -ano | findstr :5432

# Check disk space
dir data\postgres
```

#### Connection Refused
```bash
# Verify PostgreSQL is running
docker-compose -f docker-compose.new.yml ps postgres

# Test connection
docker exec mcp-postgres pg_isready -U mcp_user -d mcp_gateway

# Check network
docker network ls
docker network inspect mcpnet
```

#### MCP Gateway Can't Connect to PostgreSQL
```bash
# Check Gateway logs
docker-compose -f docker-compose.new.yml logs mcp-gateway

# Verify DATABASE_URL
echo %DATABASE_URL%

# Test connection from Gateway container
docker exec mcp-gateway ping postgres
```

#### Proxy Issues (Network Timeout)
If you're behind a corporate proxy, ensure these are set in `.env`:
```bash
PROXY_SERVER=http://host.docker.internal:3128
PROXY_BYPASS=localhost,127.0.0.1,postgres,pgadmin
```

And configure Docker to use the proxy:
```bash
# Configure Docker proxy
docker config create proxy.json '{"proxies":{"default":{"httpProxy":"http://host.docker.internal:3128","httpsProxy":"http://host.docker.internal:3128","noProxy":"localhost,127.0.0.1"}}}'
```

### Performance Issues

#### Slow Queries
```bash
# Enable query logging
docker exec mcp-postgres psql -U mcp_user -d mcp_gateway -c "ALTER SYSTEM SET log_min_duration_statement = 100; SELECT pg_reload_conf();"

# Check slow queries
docker exec mcp-postgres psql -U mcp_user -d mcp_gateway -c "SELECT query, calls, total_time, mean_time FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"
```

#### Memory Issues
```bash
# Check memory usage
docker stats mcp-postgres

# Tune memory settings
docker exec mcp-postgres psql -U mcp_user -d mcp_gateway -c "ALTER SYSTEM SET shared_buffers = '256MB'; SELECT pg_reload_conf();"
```

## 📊 Monitoring and Maintenance

### Health Checks
```bash
# PostgreSQL health check
docker exec mcp-postgres pg_isready -U mcp_user -d mcp_gateway

# Database size
docker exec mcp-postgres psql -U mcp_user -d mcp_gateway -c "SELECT pg_size_pretty(pg_database_size('mcp_gateway'));"

# Connection count
docker exec mcp-postgres psql -U mcp_user -d mcp_gateway -c "SELECT count(*) FROM pg_stat_activity;"
```

### Maintenance Tasks
```bash
# Vacuum and analyze
docker exec mcp-postgres psql -U mcp_user -d mcp_gateway -c "VACUUM ANALYZE;"

# Reindex database
docker exec mcp-postgres psql -U mcp_user -d mcp_gateway -c "REINDEX DATABASE mcp_gateway;"

# Update statistics
docker exec mcp-postgres psql -U mcp_user -d mcp_gateway -c "ANALYZE;"
```

## 🔒 Security Best Practices

1. **Use strong passwords** for PostgreSQL and PgAdmin
2. **Limit network access** to PostgreSQL port (5432)
3. **Enable SSL** connections in production
4. **Regular backups** with encryption
5. **Monitor access logs** for suspicious activity
6. **Keep PostgreSQL updated** to latest version
7. **Use least privilege** principle for database users

## 📚 Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker PostgreSQL Image](https://hub.docker.com/_/postgres)
- [PgAdmin Documentation](https://www.pgadmin.org/docs/)
- [MCP Gateway Documentation](README.NEW_STRUCTURE.md)

## 🎉 Success!

Your MCP Gateway is now running with PostgreSQL - a production-ready database that provides better performance, scalability, and reliability than SQLite!

**Next Steps:**
1. Explore your MCP Gateway at `http://localhost:4444`
2. Set up regular backups
3. Configure monitoring and alerts
4. Consider replication for high availability

Enjoy your enhanced MCP Gateway with PostgreSQL! 🚀