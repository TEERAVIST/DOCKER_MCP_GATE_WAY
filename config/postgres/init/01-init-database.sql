-- MCP Gateway PostgreSQL Database Initialization Script
-- This script initializes the database with required schemas and tables

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create MCP Gateway specific schemas
CREATE SCHEMA IF NOT EXISTS mcp_gateway;
CREATE SCHEMA IF NOT EXISTS mcp_logs;
CREATE SCHEMA IF NOT EXISTS mcp_cache;
CREATE SCHEMA IF NOT EXISTS mcp_plugins;

-- Set default permissions
ALTER SCHEMA mcp_gateway OWNER TO ${POSTGRES_USER};
ALTER SCHEMA mcp_logs OWNER TO ${POSTGRES_USER};
ALTER SCHEMA mcp_cache OWNER TO ${POSTGRES_USER};
ALTER SCHEMA mcp_plugins OWNER TO ${POSTGRES_USER};

-- Create admin user for MCP Gateway (if different from POSTGRES_USER)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'mcp_admin') THEN
        CREATE ROLE mcp_admin LOGIN PASSWORD 'mcp_admin_password';
    END IF;
END
$$;

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA mcp_gateway TO mcp_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA mcp_logs TO mcp_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA mcp_cache TO mcp_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA mcp_plugins TO mcp_admin;

GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA mcp_gateway TO mcp_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA mcp_logs TO mcp_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA mcp_cache TO mcp_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA mcp_plugins TO mcp_admin;

-- Create performance optimization settings
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
ALTER SYSTEM SET track_activity_query_size = 2048;
ALTER SYSTEM SET log_min_duration_statement = 1000;

-- Create indexes for common queries (will be populated by MCP Gateway)
-- These are placeholders that the application will create as needed

-- Log initialization
INSERT INTO mcp_logs.init_log (timestamp, message, status) 
VALUES (NOW(), 'PostgreSQL database initialized for MCP Gateway', 'SUCCESS');

-- Create configuration table for MCP Gateway settings
CREATE TABLE IF NOT EXISTS mcp_gateway.config (
    id SERIAL PRIMARY KEY,
    key VARCHAR(255) UNIQUE NOT NULL,
    value TEXT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default configuration
INSERT INTO mcp_gateway.config (key, value, description) VALUES
('database_version', '1.0.0', 'Database schema version'),
('init_timestamp', NOW(), 'Database initialization timestamp'),
('mcp_gateway_version', '0.8.0', 'MCP Gateway application version')
ON CONFLICT (key) DO NOTHING;

-- Create audit log table
CREATE TABLE IF NOT EXISTS mcp_logs.audit_log (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255),
    action VARCHAR(255) NOT NULL,
    resource VARCHAR(255),
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_audit_timestamp (timestamp),
    INDEX idx_audit_user (user_id),
    INDEX idx_audit_action (action)
);

-- Create session table for MCP Gateway
CREATE TABLE IF NOT EXISTS mcp_gateway.sessions (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    data JSONB,
    last_accessed TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_sessions_user (user_id),
    INDEX idx_sessions_expires (expires_at)
);

-- Create plugin registry table
CREATE TABLE IF NOT EXISTS mcp_plugins.registry (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    version VARCHAR(50) NOT NULL,
    description TEXT,
    enabled BOOLEAN DEFAULT true,
    config JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_plugins_name (name),
    INDEX idx_plugins_enabled (enabled)
);

COMMIT;

-- Output success message
\echo 'MCP Gateway PostgreSQL database initialized successfully!'