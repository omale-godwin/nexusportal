#!/bin/bash

# ============================================================================
# METABASE RESTORE SCRIPT
# ============================================================================

set -e

# Configuration
BACKUP_DIR="$(cd "$(dirname "$0")/.." && pwd)/backup"
LOG_FILE="${BACKUP_DIR}/restore.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging function
log() {
    echo -e "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a "${LOG_FILE}"
}

# Show available backups
show_backups() {
    echo -e "\n${YELLOW}Available backups:${NC}"
    echo "=================="
    ls -lh "${BACKUP_DIR}" | grep "metabase1_.*\.sql" | while read -r line; do
        echo "  $line"
    done
    echo ""
}

# Check if backup exists
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: Please provide timestamp (e.g., 20240308_143022)${NC}"
    show_backups
    exit 1
fi

TIMESTAMP=$1
BACKUP_FILE="${BACKUP_DIR}/metabase1_${TIMESTAMP}.sql"
DATA_BACKUP="${BACKUP_DIR}/metabase_data_${TIMESTAMP}.tar.gz"

if [ ! -f "${BACKUP_FILE}" ]; then
    echo -e "${RED}Error: Backup file not found: ${BACKUP_FILE}${NC}"
    show_backups
    exit 1
fi

log "${YELLOW}Starting restore from backup ${TIMESTAMP}...${NC}"

# Stop Metabase instances
log "Stopping Metabase instances..."
docker-compose stop metabase1 metabase2

# Restore PostgreSQL databases
log "Restoring PostgreSQL databases..."

# Drop and recreate databases
docker exec postgres-metabase psql -U metabase -d postgres -c "DROP DATABASE IF EXISTS metabase1;"
docker exec postgres-metabase psql -U metabase -d postgres -c "CREATE DATABASE metabase1 OWNER metabase;"

# Restore from backup
cat "${BACKUP_DIR}/metabase1_${TIMESTAMP}.sql" | docker exec -i postgres-metabase psql -U metabase -d metabase1

if [ -f "${BACKUP_DIR}/metabase2_${TIMESTAMP}.sql" ]; then
    docker exec postgres-metabase psql -U metabase -d postgres -c "DROP DATABASE IF EXISTS metabase2;"
    docker exec postgres-metabase psql -U metabase -d postgres -c "CREATE DATABASE metabase2 OWNER metabase;"
    cat "${BACKUP_DIR}/metabase2_${TIMESTAMP}.sql" | docker exec -i postgres-metabase psql -U metabase -d metabase2
fi

# Restore data directories if available
if [ -f "${DATA_BACKUP}" ]; then
    log "Restoring data directories..."
    tar -xzf "${DATA_BACKUP}" -C "$(dirname "$0")/.."
fi

# Start Metabase instances
log "Starting Metabase instances..."
docker-compose start metabase1 metabase2

log "${GREEN}Restore completed successfully!${NC}"