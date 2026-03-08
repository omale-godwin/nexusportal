#!/bin/bash

# ============================================================================
# METABASE BACKUP SCRIPT
# ============================================================================

set -e

# Configuration
BACKUP_DIR="$(cd "$(dirname "$0")/.." && pwd)/backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RETENTION_DAYS=7
LOG_FILE="${BACKUP_DIR}/backup.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Logging function
log() {
    echo -e "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a "${LOG_FILE}"
}

# Start backup
log "${GREEN}Starting Metabase backup...${NC}"

# Check if PostgreSQL container is running
if ! docker ps | grep -q postgres-metabase; then
    log "${RED}Error: postgres-metabase container is not running${NC}"
    exit 1
fi

# Backup PostgreSQL databases
log "${YELLOW}Backing up PostgreSQL databases...${NC}"

# Backup metabase_main
log "Backing up metabase_main..."
docker exec postgres-metabase pg_dump -U metabase metabase_main > "${BACKUP_DIR}/metabase_main_${TIMESTAMP}.sql"
if [ $? -eq 0 ]; then
    log "${GREEN}✓ metabase_main backup successful${NC}"
else
    log "${RED}✗ metabase_main backup failed${NC}"
    exit 1
fi

# Backup metabase1
log "Backing up metabase1..."
docker exec postgres-metabase pg_dump -U metabase metabase1 > "${BACKUP_DIR}/metabase1_${TIMESTAMP}.sql"
if [ $? -eq 0 ]; then
    log "${GREEN}✓ metabase1 backup successful${NC}"
else
    log "${RED}✗ metabase1 backup failed${NC}"
fi

# Backup metabase2
log "Backing up metabase2..."
docker exec postgres-metabase pg_dump -U metabase metabase2 > "${BACKUP_DIR}/metabase2_${TIMESTAMP}.sql"
if [ $? -eq 0 ]; then
    log "${GREEN}✓ metabase2 backup successful${NC}"
else
    log "${RED}✗ metabase2 backup failed${NC}"
fi

# Backup Docker volumes (data directories)
log "${YELLOW}Backing up data directories...${NC}"

# Create data backup archive
tar -czf "${BACKUP_DIR}/metabase_data_${TIMESTAMP}.tar.gz" \
    -C "$(dirname "$0")/.." \
    postgres-data \
    metabase1-data \
    metabase2-data \
    2>/dev/null

if [ $? -eq 0 ]; then
    log "${GREEN}✓ Data directories backup successful${NC}"
else
    log "${RED}✗ Data directories backup failed${NC}"
fi

# Backup docker-compose and .env files
log "${YELLOW}Backing up configuration files...${NC}"
cp "$(dirname "$0")/../docker-compose.yml" "${BACKUP_DIR}/docker-compose_${TIMESTAMP}.yml"
cp "$(dirname "$0")/../.env" "${BACKUP_DIR}/env_${TIMESTAMP}.backup"
log "${GREEN}✓ Configuration backup successful${NC}"

# Remove backups older than RETENTION_DAYS
log "${YELLOW}Cleaning up backups older than ${RETENTION_DAYS} days...${NC}"
find "${BACKUP_DIR}" -name "*.sql" -type f -mtime +${RETENTION_DAYS} -delete
find "${BACKUP_DIR}" -name "*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete
find "${BACKUP_DIR}" -name "*.yml" -type f -mtime +${RETENTION_DAYS} -delete
find "${BACKUP_DIR}" -name "*.backup" -type f -mtime +${RETENTION_DAYS} -delete

# Create backup summary
log "${GREEN}Creating backup summary...${NC}"
cat > "${BACKUP_DIR}/backup_summary_${TIMESTAMP}.txt" << EOF
Metabase Backup Summary
=======================
Date: $(date)
Timestamp: ${TIMESTAMP}

Backup Files:
- metabase_main_${TIMESTAMP}.sql
- metabase1_${TIMESTAMP}.sql
- metabase2_${TIMESTAMP}.sql
- metabase_data_${TIMESTAMP}.tar.gz
- docker-compose_${TIMESTAMP}.yml
- env_${TIMESTAMP}.backup

Retention Policy: ${RETENTION_DAYS} days
EOF

# Calculate backup size
BACKUP_SIZE=$(du -sh "${BACKUP_DIR}" | cut -f1)
log "${GREEN}Backup completed successfully! Total backup size: ${BACKUP_SIZE}${NC}"

# List latest backups
log "${YELLOW}Latest backups:${NC}"
ls -lh "${BACKUP_DIR}" | tail -5