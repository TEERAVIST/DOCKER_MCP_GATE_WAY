#!/bin/bash

# MCP Gateway Backup Script
# This script creates backups of critical data and configuration files

set -euo pipefail

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"
DATA_DIR="${DATA_DIR:-./data}"
LOG_DIR="${LOG_DIR:-./logs}"
CONFIG_FILES=".env docker-compose.yml"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="mcp_backup_${DATE}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"

echo "=== MCP Gateway Backup Script ==="
echo "Backup started at: $(date)"
echo "Backup name: ${BACKUP_NAME}"

# Create backup directory
mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}"
echo "Created backup directory: ${BACKUP_DIR}/${BACKUP_NAME}"

# Backup data directories
echo "Backing up data directories..."
if [ -d "${DATA_DIR}" ]; then
    tar -czf "${BACKUP_DIR}/${BACKUP_NAME}/data.tar.gz" -C "$(dirname "${DATA_DIR}")" "$(basename "${DATA_DIR}")"
    echo "✓ Data directory backed up"
else
    echo "⚠ Data directory not found: ${DATA_DIR}"
fi

# Backup logs
echo "Backing up logs..."
if [ -d "${LOG_DIR}" ]; then
    tar -czf "${BACKUP_DIR}/${BACKUP_NAME}/logs.tar.gz" -C "$(dirname "${LOG_DIR}")" "$(basename "${LOG_DIR}")"
    echo "✓ Logs backed up"
else
    echo "⚠ Log directory not found: ${LOG_DIR}"
fi

# Backup configuration files
echo "Backing up configuration files..."
mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}/config"
for file in ${CONFIG_FILES}; do
    if [ -f "$file" ]; then
        cp "$file" "${BACKUP_DIR}/${BACKUP_NAME}/config/"
        echo "✓ $file backed up"
    else
        echo "⚠ Configuration file not found: $file"
    fi
fi

# Create backup metadata
cat > "${BACKUP_DIR}/${BACKUP_NAME}/backup_info.txt" << EOF
MCP Gateway Backup Information
==============================
Backup Name: ${BACKUP_NAME}
Created: $(date)
Hostname: $(hostname)
User: $(whoami)
Working Directory: $(pwd)

Docker Information:
$(docker --version 2>/dev/null || echo "Docker not available")
$(docker-compose --version 2>/dev/null || echo "Docker Compose not available")

Running Services:
$(docker-compose ps 2>/dev/null || echo "No running services")

Disk Usage:
$(df -h "${BACKUP_DIR}" 2>/dev/null || echo "Disk usage not available")
EOF

# Create backup manifest
find "${BACKUP_DIR}/${BACKUP_NAME}" -type f -exec sha256sum {} \; > "${BACKUP_DIR}/${BACKUP_NAME}/checksums.txt"
echo "✓ Backup manifest created"

# Compress entire backup
echo "Compressing backup..."
cd "${BACKUP_DIR}"
tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"
rm -rf "${BACKUP_NAME}"

echo "✓ Backup completed: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
echo "Backup size: $(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)"

# Clean up old backups
echo "Cleaning up old backups (older than ${RETENTION_DAYS} days)..."
find "${BACKUP_DIR}" -name "mcp_backup_*.tar.gz" -mtime +${RETENTION_DAYS} -delete
echo "✓ Old backups cleaned up"

echo "=== Backup completed successfully ==="
echo "Backup file: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
echo "Completed at: $(date)"

# Verify backup integrity
echo "Verifying backup integrity..."
if tar -tzf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" > /dev/null 2>&1; then
    echo "✓ Backup integrity verified"
else
    echo "✗ Backup integrity check failed"
    exit 1
fi

echo "Backup script completed successfully!"