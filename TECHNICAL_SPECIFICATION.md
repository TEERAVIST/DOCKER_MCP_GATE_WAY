# Technical Specification for Docker Compose Restructuring

## Compose Files Detailed Configuration

### 1. compose.core.yml

**Purpose**: Core MCP Gateway service with authentication and persistence

**Services**:
- `mcp-gateway`: Main gateway with Admin UI

**Key Features**:
- Profiles: `["core", "all", "minimal"]`
- SQLite persistence
- JWT authentication
- Admin API enabled
- Health checks
- Resource limits

**Configuration**:
```yaml
version: "3.9"
services:
  mcp-gateway:
    image: ghcr.io/ibm/mcp-context-forge:0.8.0
    container_name: mcp-gateway
    ports:
      - "${MCP_GATEWAY_PORT:-4444}:4444"
    environment:
      MCPGATEWAY_UI_ENABLED: "true"
      PLUGINS_ENABLED: "true"
      MCPGATEWAY_ADMIN_API_ENABLED: "true"
      HOST: "0.0.0.0"
      PORT: "4444"
      JWT_SECRET_KEY: "${JWT_SECRET_KEY}"
      BASIC_AUTH_USER: "${BASIC_AUTH_USER}"
      BASIC_AUTH_PASSWORD: "${BASIC_AUTH_PASSWORD}"
      AUTH_REQUIRED: "${AUTH_REQUIRED:-true}"
      PLATFORM_ADMIN_EMAIL: "${PLATFORM_ADMIN_EMAIL}"
      PLATFORM_ADMIN_PASSWORD: "${PLATFORM_ADMIN_PASSWORD}"
      PLATFORM_ADMIN_FULL_NAME: "${PLATFORM_ADMIN_FULL_NAME}"
      DATABASE_URL: "sqlite:////data/mcp.db"
    volumes:
      - ${DATA_DIR:-./data}/mcp:/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://localhost:4444/health || exit 1"]
      interval: ${HEALTH_CHECK_INTERVAL:-30s}
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          memory: ${MCP_GATEWAY_MEMORY_LIMIT:-512m}
          cpus: '${MCP_GATEWAY_CPU_LIMIT:-0.5}'
    profiles: ["core", "all", "minimal"]
```

### 2. compose.net.yml

**Purpose**: Networking configuration and shared settings

**Configuration**:
```yaml
version: "3.9"
networks:
  mcpnet:
    name: ${NETWORK_NAME:-mcpnet}
    driver: bridge
    ipam:
      config:
        - subnet: ${NETWORK_SUBNET:-172.20.0.0/16}

volumes:
  mcp_data:
    driver: local
  kaggle_data:
    driver: local
  playwright_data:
    driver: local

# Common environment variables template
x-common-variables: &common-variables
  http_proxy: "${PROXY_SERVER}"
  https_proxy: "${PROXY_SERVER}"
  HTTP_PROXY: "${PROXY_SERVER}"
  HTTPS_PROXY: "${PROXY_SERVER}"
  no_proxy: "${PROXY_BYPASS}"
  NO_PROXY: "${PROXY_BYPASS}"
  TZ: "${TIMEZONE:-UTC}"

# Common bridge configuration
x-bridge-config: &bridge-config
  extra_hosts:
    - "host.docker.internal:host-gateway"
  restart: unless-stopped
  networks:
    - mcpnet
```

### 3. compose.data.yml

**Purpose**: Data-related services (Kaggle and MSSQL bridges)

**Services**:
- `kaggle-bridge`: Kaggle MCP bridge
- `mssql-bridge`: SQL Server MCP bridge

**Key Features**:
- Profiles: `["data", "all"]`
- Persistent data storage
- Proxy support
- Health checks
- Resource limits

**Configuration**:
```yaml
version: "3.9"
services:
  kaggle-bridge:
    image: python:3.11-slim
    container_name: kaggle-bridge
    env_file: .env
    <<: *bridge-config
    environment:
      <<: *common-variables
      KAGGLE_USERNAME: "${KAGGLE_USERNAME}"
      KAGGLE_KEY: "${KAGGLE_KEY}"
    volumes:
      - ${DATA_DIR:-./data}/kaggle:/data
      ${KAGGLE_DATA_DIR:-./kaggle-data}:/kaggle-data
    command:
      - bash
      - -lc
      - >
        set -euo pipefail &&
        export http_proxy="${PROXY_SERVER:-}"; export https_proxy="${PROXY_SERVER:-}";
        export HTTP_PROXY="$http_proxy"; export HTTPS_PROXY="$https_proxy";
        export no_proxy="${PROXY_BYPASS:-localhost,127.0.0.1}"; export NO_PROXY="$no_proxy";
        apt-get update &&
        apt-get install -y --no-install-recommends git ca-certificates &&
        rm -rf /var/lib/apt/lists/* &&
        pip install --no-cache-dir --upgrade pip mcp-contextforge-gateway &&
        rm -rf /app/kaggle-mcp &&
        git clone --depth=1 https://github.com/arrismo/kaggle-mcp /app/kaggle-mcp &&
        pip install --no-cache-dir -r /app/kaggle-mcp/requirements.txt &&
        printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' \
          'cd /app/kaggle-mcp' \
          'export PYTHONPATH="/app/kaggle-mcp/src:/app/kaggle-mcp${PYTHONPATH:+:$PYTHONPATH}"' \
          'echo "[run-kaggle-mcp] pwd=$(pwd)"; ls -la' \
          'exec python -m server' \
          > /usr/local/bin/run-kaggle-mcp.sh &&
        chmod +x /usr/local/bin/run-kaggle-mcp.sh &&
        python -m mcpgateway.translate \
          --stdio "/usr/local/bin/run-kaggle-mcp.sh" \
          --expose-sse \
          --host 0.0.0.0 \
          --port 9000
    expose:
      - "9000"
    healthcheck:
      test: ["CMD-SHELL", "curl -sS -D- http://localhost:9000/sse --max-time 2 | grep -q 'HTTP/1.1 200'"]
      interval: ${HEALTH_CHECK_INTERVAL:-30s}
      timeout: 3s
      retries: 5
    deploy:
      resources:
        limits:
          memory: ${KAGGLE_BRIDGE_MEMORY_LIMIT:-256m}
          cpus: '${KAGGLE_BRIDGE_CPU_LIMIT:-0.3}'
    profiles: ["data", "all"]

  mssql-bridge:
    image: python:3.11-slim
    container_name: mssql-bridge
    env_file: .env
    <<: *bridge-config
    environment:
      <<: *common-variables
      MSSQL_SERVER: "${MSSQL_SERVER}"
      MSSQL_DATABASE: "${MSSQL_DATABASE}"
      MSSQL_USER: "${MSSQL_USER}"
      MSSQL_PASSWORD: "${MSSQL_PASSWORD}"
      MSSQL_PORT: "${MSSQL_PORT}"
    command:
      - bash
      - -lc
      - |
        set -euo pipefail
        export http_proxy="${PROXY_SERVER:-}"; export https_proxy="${PROXY_SERVER:-}";
        export HTTP_PROXY="$http_proxy"; export HTTPS_PROXY="$https_proxy";
        export no_proxy="${PROXY_BYPASS:-localhost,127.0.0.1}"; export NO_PROXY="$no_proxy";
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y --no-install-recommends ca-certificates gcc g++ unixodbc-dev curl
        rm -rf /var/lib/apt/lists/*

        pip install --no-cache-dir --upgrade pip mcp-contextforge-gateway
        pip install --no-cache-dir microsoft_sql_server_mcp python-tds pymssql

        mkdir -p /app/patch
        cat >/app/patch/sitecustomize.py <<'PY'
        import sys
        sys.stderr.write("[sitecustomize] loaded\n")
        try:
            import pymssql as _pymssql
            _orig = _pymssql.connect
            def _connect(*args, **kwargs):
                if 'encrypt' in kwargs:
                    v = kwargs.pop('encrypt')
                    on = v if isinstance(v, bool) else str(v).lower() in ('1','true','yes','on')
                    kwargs['encryption'] = 'require' if on else 'off'
                kwargs.pop('trust_server_certificate', None)
                kwargs.pop('trustServerCertificate', None)
                return _orig(*args, **kwargs)
            _pymssql.connect = _connect
            sys.stderr.write("[sitecustomize] pymssql.connect patched\n")
        except Exception as e:
            sys.stderr.write(f"[sitecustomize] patch skipped: {e}\n")
        PY
        export PYTHONPATH="/app/patch${PYTHONPATH:+:$PYTHONPATH}"
        unset MSSQL_ENCRYPT MSSQL_TRUST_SERVER_CERTIFICATE || true
        python -m mcpgateway.translate --stdio "python -m mssql_mcp_server" --expose-sse --host 0.0.0.0 --port 9020
    expose:
      - "9020"
    healthcheck:
      test: ["CMD-SHELL", "curl -sS -D- http://localhost:9020/sse --max-time 2 | grep -q 'HTTP/1.1 200'"]
      interval: ${HEALTH_CHECK_INTERVAL:-30s}
      timeout: 3s
      retries: 5
    deploy:
      resources:
        limits:
          memory: ${MSSQL_BRIDGE_MEMORY_LIMIT:-256m}
          cpus: '${MSSQL_BRIDGE_CPU_LIMIT:-0.3}'
    profiles: ["data", "all"]
```

### 4. compose.ai.yml

**Purpose**: AI/ML related services (Context7 and Gistpad)

**Services**:
- `context7-bridge`: Context7 AI/ML documentation service
- `gistpad-bridge`: GitHub Gist management service

**Key Features**:
- Profiles: `["ai", "all"]`
- API key management
- Proxy support
- Health checks

### 5. compose.browser.yml

**Purpose**: Browser automation services

**Services**:
- `playwright-bridge`: Browser automation and web scraping

**Key Features**:
- Profiles: `["browser", "all"]`
- Shared memory configuration
- Persistent data storage
- Browser automation tools

### 6. Main docker-compose.yml

**Purpose**: Orchestrator that includes all compose files

**Configuration**:
```yaml
version: "3.9"
include:
  - compose/compose.net.yml
  - compose/compose.core.yml
  - compose/compose.data.yml
  - compose/compose.ai.yml
  - compose/compose.browser.yml
```

## Environment Variables Enhancement

### Production-Ready .env.example

```bash
# ===== SECURITY CONFIGURATION =====
JWT_SECRET_KEY=your-super-secret-jwt-key-for-mcp-gateway-2025-change-in-production
BASIC_AUTH_USER=admin
BASIC_AUTH_PASSWORD=changeme-in-production
AUTH_REQUIRED=true
PLATFORM_ADMIN_EMAIL=admin@example.com
PLATFORM_ADMIN_PASSWORD=changeme-in-production
PLATFORM_ADMIN_FULL_NAME=Platform Administrator

# ===== NETWORKING CONFIGURATION =====
MCP_GATEWAY_PORT=4444
PROXY_SERVER=http://host.docker.internal:3128
PROXY_BYPASS=localhost,127.0.0.1,mcp-gateway,playwright-bridge,kaggle-bridge,gistpad-bridge,context7-bridge,mssql-bridge,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
NETWORK_NAME=mcpnet
NETWORK_SUBNET=172.20.0.0/16
TIMEZONE=UTC

# ===== STORAGE CONFIGURATION =====
DATA_DIR=./data
LOG_DIR=./logs
BACKUP_DIR=./backups
KAGGLE_DATA_DIR=./kaggle-data

# ===== MONITORING CONFIGURATION =====
HEALTH_CHECK_INTERVAL=30s
LOG_LEVEL=INFO
METRICS_ENABLED=true

# ===== PERFORMANCE CONFIGURATION =====
MCP_GATEWAY_MEMORY_LIMIT=512m
MCP_GATEWAY_CPU_LIMIT=0.5
KAGGLE_BRIDGE_MEMORY_LIMIT=256m
KAGGLE_BRIDGE_CPU_LIMIT=0.3
MSSQL_BRIDGE_MEMORY_LIMIT=256m
MSSQL_BRIDGE_CPU_LIMIT=0.3
CONTEXT7_BRIDGE_MEMORY_LIMIT=256m
CONTEXT7_BRIDGE_CPU_LIMIT=0.3
GISTPAD_BRIDGE_MEMORY_LIMIT=256m
GISTPAD_BRIDGE_CPU_LIMIT=0.3
PLAYWRIGHT_BRIDGE_MEMORY_LIMIT=1g
PLAYWRIGHT_BRIDGE_CPU_LIMIT=1.0
SHM_SIZE=1g

# ===== EXTERNAL SERVICES CONFIGURATION =====
# Kaggle Configuration
KAGGLE_USERNAME=your-kaggle-username
KAGGLE_KEY=your-kaggle-api-key

# SQL Server Configuration
MSSQL_SERVER=host.docker.internal
MSSQL_DATABASE=your-database
MSSQL_USER=your-username
MSSQL_PASSWORD=your-password
MSSQL_PORT=1433

# Context7 Configuration
CONTEXT7_API_KEY=your-context7-api-key

# GitHub Configuration
GITHUB_TOKEN=your-github-personal-access-token
```

## Profile Usage Examples

```bash
# Start all services
docker-compose --profile all up -d

# Start only core gateway
docker-compose --profile core up -d

# Start data services only
docker-compose --profile data up -d

# Start AI services only
docker-compose --profile ai up -d

# Start browser services only
docker-compose --profile browser up -d

# Start minimal setup (core + essential)
docker-compose --profile minimal up -d

# Start multiple profiles
docker-compose --profile core --profile data up -d

# Stop specific profile services
docker-compose --profile data down

# View logs for specific profile
docker-compose --profile ai logs -f
```

## Health Check Implementation

Each service includes comprehensive health checks:
- HTTP endpoint checks
- Service-specific validation
- Configurable intervals and timeouts
- Retry mechanisms
- Graceful degradation

## Resource Management

Production-ready resource limits:
- Memory constraints per service
- CPU allocation limits
- Shared memory for browser services
- Disk space monitoring
- Network bandwidth considerations

## Security Enhancements

- Secret management through environment variables
- Network isolation via dedicated networks
- Container resource limits
- Health check isolation
- Proxy configuration for secure external access
- Authentication and authorization

This technical specification provides the exact implementation details needed to create a production-ready, modular Docker Compose architecture.