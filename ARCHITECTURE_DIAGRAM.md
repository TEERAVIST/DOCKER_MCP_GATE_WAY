# Architecture Diagram for Restructured Docker MCP Gateway

## System Architecture Overview

```mermaid
graph TB
    subgraph "Docker Host"
        subgraph "Main Orchestrator"
            DC[docker-compose.yml]
        end
        
        subgraph "Compose Files"
            CORE[compose.core.yml]
            NET[compose.net.yml]
            DATA[compose.data.yml]
            AI[compose.ai.yml]
            BROWSER[compose.browser.yml]
        end
        
        subgraph "Services"
            subgraph "Core Services"
                GW[mcp-gateway:4444]
            end
            
            subgraph "Data Services"
                KAG[kaggle-bridge:9000]
                SQL[mssql-bridge:9020]
            end
            
            subgraph "AI/ML Services"
                CTX[context7-bridge:9030]
                GIST[gistpad-bridge:9010]
            end
            
            subgraph "Browser Services"
                PLAY[playwright-bridge:9040]
            end
        end
        
        subgraph "Network Layer"
            NET[mcpnet<br/>172.20.0.0/16]
        end
        
        subgraph "Storage Layer"
            MCP_DATA[data/mcp/]
            KAG_DATA[data/kaggle/]
            PLAY_DATA[data/playwright/]
            LOGS[logs/]
        end
        
        subgraph "External Services"
            KAG_API[Kaggle API]
            SQL_SERVER[SQL Server]
            CTX_API[Context7 API]
            GITHUB[GitHub API]
            WEB[Web Targets]
        end
    end
    
    %% Connections
    DC --> CORE
    DC --> NET
    DC --> DATA
    DC --> AI
    DC --> BROWSER
    
    CORE --> GW
    DATA --> KAG
    DATA --> SQL
    AI --> CTX
    AI --> GIST
    BROWSER --> PLAY
    
    GW -.-> NET
    KAG -.-> NET
    SQL -.-> NET
    CTX -.-> NET
    GIST -.-> NET
    PLAY -.-> NET
    
    GW --> MCP_DATA
    KAG --> KAG_DATA
    PLAY --> PLAY_DATA
    
    KAG --> KAG_API
    SQL --> SQL_SERVER
    CTX --> CTX_API
    GIST --> GITHUB
    PLAY --> WEB
    
    GW -.-> LOGS
    KAG -.-> LOGS
    SQL -.-> LOGS
    CTX -.-> LOGS
    GIST -.-> LOGS
    PLAY -.-> LOGS
```

## Profile-Based Service Grouping

```mermaid
graph LR
    subgraph "Profile Configuration"
        ALL[Profile: all]
        CORE[Profile: core]
        DATA[Profile: data]
        AI[Profile: ai]
        BROWSER[Profile: browser]
        MINIMAL[Profile: minimal]
    end
    
    subgraph "Service Mapping"
        GW[mcp-gateway]
        KAG[kaggle-bridge]
        SQL[mssql-bridge]
        CTX[context7-bridge]
        GIST[gistpad-bridge]
        PLAY[playwright-bridge]
    end
    
    ALL --> GW
    ALL --> KAG
    ALL --> SQL
    ALL --> CTX
    ALL --> GIST
    ALL --> PLAY
    
    CORE --> GW
    MINIMAL --> GW
    
    DATA --> KAG
    DATA --> SQL
    
    AI --> CTX
    AI --> GIST
    
    BROWSER --> PLAY
```

## Network Architecture

```mermaid
graph TB
    subgraph "Docker Network: mcpnet"
        subgraph "Gateway Layer"
            GW[mcp-gateway<br/>Port: 4444<br/>Host: 0.0.0.0]
        end
        
        subgraph "Bridge Services"
            KAG[kaggle-bridge<br/>Port: 9000<br/>Internal Only]
            SQL[mssql-bridge<br/>Port: 9020<br/>Internal Only]
            CTX[context7-bridge<br/>Port: 9030<br/>Internal Only]
            GIST[gistpad-bridge<br/>Port: 9010<br/>Internal Only]
            PLAY[playwright-bridge<br/>Port: 9040<br/>Internal Only]
        end
    end
    
    subgraph "Host System"
        HOST[Host Machine<br/>Windows 11]
        PROXY[Squid Proxy<br/>Port: 3128]
    end
    
    subgraph "External Networks"
        INTERNET[Internet]
        VPN[VPN/Corporate Network]
    end
    
    %% Connections
    HOST --> GW
    GW -.-> KAG
    GW -.-> SQL
    GW -.-> CTX
    GW -.-> GIST
    GW -.-> PLAY
    
    KAG --> PROXY
    SQL --> PROXY
    CTX --> PROXY
    GIST --> PROXY
    PLAY --> PROXY
    
    PROXY --> VPN
    VPN --> INTERNET
    
    HOST --> PROXY
```

## Data Flow Architecture

```mermaid
sequenceDiagram
    participant Client as Client Application
    participant GW as mcp-gateway
    participant KAG as kaggle-bridge
    participant SQL as mssql-bridge
    participant CTX as context7-bridge
    participant GIST as gistpad-bridge
    participant PLAY as playwright-bridge
    participant Ext as External Services
    
    Client->>GW: HTTP Request
    GW->>GW: Authentication & Authorization
    
    alt Data Request
        GW->>KAG: SSE Connection
        KAG->>Ext: Kaggle API Call
        Ext-->>KAG: Data Response
        KAG-->>GW: Processed Data
        GW-->>Client: Response
    end
    
    alt Database Request
        GW->>SQL: SSE Connection
        SQL->>Ext: SQL Query
        Ext-->>SQL: Query Results
        SQL-->>GW: Processed Results
        GW-->>Client: Response
    end
    
    alt AI/ML Request
        GW->>CTX: SSE Connection
        CTX->>Ext: Context7 API
        Ext-->>CTX: AI/ML Response
        CTX-->>GW: Processed Response
        GW-->>Client: Response
    end
    
    alt GitHub Request
        GW->>GIST: SSE Connection
        GIST->>Ext: GitHub API
        Ext-->>GIST: GitHub Data
        GIST-->>GW: Processed Data
        GW-->>Client: Response
    end
    
    alt Browser Automation
        GW->>PLAY: SSE Connection
        PLAY->>Ext: Web Automation
        Ext-->>PLAY: Browser Results
        PLAY-->>GW: Processed Results
        GW-->>Client: Response
    end
```

## Storage Architecture

```mermaid
graph TB
    subgraph "Persistent Storage"
        subgraph "Data Directory"
            MCP[data/mcp/]
            KAG[data/kaggle/]
            PLAY[data/playwright/]
        end
        
        subgraph "Log Directory"
            LOGS[logs/]
        end
        
        subgraph "Backup Directory"
            BACKUP[backups/]
        end
    end
    
    subgraph "Service Data Mapping"
        GW_SVC[mcp-gateway]
        KAG_SVC[kaggle-bridge]
        PLAY_SVC[playwright-bridge]
        ALL_SVC[All Services]
    end
    
    GW_SVC --> MCP
    GW_SVC --> LOGS
    KAG_SVC --> KAG
    KAG_SVC --> LOGS
    PLAY_SVC --> PLAY
    PLAY_SVC --> LOGS
    ALL_SVC --> BACKUP
    
    subgraph "Storage Types"
        SQLITE[SQLite Database]
        DATASETS[Kaggle Datasets]
        ARTIFACTS[Browser Artifacts<br/>Screenshots, Videos, Traces]
        LOG_FILES[Application Logs]
        BACKUP_FILES[Backup Archives]
    end
    
    MCP --> SQLITE
    KAG --> DATASETS
    PLAY --> ARTIFACTS
    LOGS --> LOG_FILES
    BACKUP --> BACKUP_FILES
```

## Security Architecture

```mermaid
graph TB
    subgraph "Security Layers"
        subgraph "Authentication Layer"
            JWT[JWT Authentication]
            BASIC[Basic Auth]
            ADMIN[Admin API]
        end
        
        subgraph "Network Security"
            DOCKER_NET[Docker Network Isolation]
            PROXY[Proxy Configuration]
            FIREWALL[Host Firewall]
        end
        
        subgraph "Data Security"
            SECRETS[Environment Secrets]
            ENCRYPT[Data Encryption]
            BACKUP_SEC[Secure Backups]
        end
        
        subgraph "Container Security"
            LIMITS[Resource Limits]
            USER[Non-root User]
            HEALTH[Health Checks]
        end
    end
    
    subgraph "Protected Assets"
        SERVICES[Container Services]
        DATA[Persistent Data]
        API[External API Access]
    end
    
    JWT --> SERVICES
    BASIC --> SERVICES
    ADMIN --> SERVICES
    
    DOCKER_NET --> SERVICES
    PROXY --> API
    FIREWALL --> SERVICES
    
    SECRETS --> SERVICES
    ENCRYPT --> DATA
    BACKUP_SEC --> DATA
    
    LIMITS --> SERVICES
    USER --> SERVICES
    HEALTH --> SERVICES
```

## Deployment Architecture

```mermaid
graph TB
    subgraph "Development Environment"
        DEV_HOST[Dev Machine]
        DEV_COMPOSE[docker-compose.yml]
        DEV_ENV[.env.dev]
        DEV_DATA[./data]
    end
    
    subgraph "Staging Environment"
        STAGE_HOST[Staging Server]
        STAGE_COMPOSE[docker-compose.yml]
        STAGE_ENV[.env.staging]
        STAGE_DATA[/opt/mcp/data]
    end
    
    subgraph "Production Environment"
        PROD_HOST[Production Server]
        PROD_COMPOSE[docker-compose.yml]
        PROD_ENV[.env.prod]
        PROD_DATA[/var/lib/mcp]
        MONITOR[Monitoring Stack]
    end
    
    subgraph "Configuration Management"
        GIT[Git Repository]
        CI[CI/CD Pipeline]
        SECRETS_MGR[Secret Manager]
    end
    
    DEV_COMPOSE --> GIT
    STAGE_COMPOSE --> GIT
    PROD_COMPOSE --> GIT
    
    GIT --> CI
    CI --> STAGE_HOST
    CI --> PROD_HOST
    
    SECRETS_MGR --> DEV_ENV
    SECRETS_MGR --> STAGE_ENV
    SECRETS_MGR --> PROD_ENV
    
    MONITOR --> PROD_HOST
```

## Service Dependencies

```mermaid
graph TD
    subgraph "Service Dependencies"
        GW[mcp-gateway]
        KAG[kaggle-bridge]
        SQL[mssql-bridge]
        CTX[context7-bridge]
        GIST[gistpad-bridge]
        PLAY[playwright-bridge]
    end
    
    subgraph "External Dependencies"
        KAG_API[Kaggle API]
        SQL_DB[SQL Server]
        CTX_API[Context7 API]
        GITHUB_API[GitHub API]
        BROWSER[Web Browsers]
        PROXY[Squid Proxy]
    end
    
    subgraph "Internal Dependencies"
        NET[Docker Network]
        VOLUMES[Persistent Volumes]
        ENV[Environment Config]
    end
    
    GW --> NET
    GW --> ENV
    
    KAG --> NET
    KAG --> VOLUMES
    KAG --> ENV
    KAG --> KAG_API
    KAG --> PROXY
    
    SQL --> NET
    SQL --> ENV
    SQL --> SQL_DB
    SQL --> PROXY
    
    CTX --> NET
    CTX --> ENV
    CTX --> CTX_API
    CTX --> PROXY
    
    GIST --> NET
    GIST --> ENV
    GIST --> GITHUB_API
    GIST --> PROXY
    
    PLAY --> NET
    PLAY --> VOLUMES
    PLAY --> ENV
    PLAY --> BROWSER
    PLAY --> PROXY
```

This architecture diagram provides a comprehensive visual representation of the restructured Docker MCP Gateway system, including service relationships, network topology, data flow, security layers, and deployment patterns.