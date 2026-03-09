#!/bin/bash

# ============================================================================
# METABASE MONITORING SCRIPT
# ============================================================================

while true; do
    clear
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   METABASE MONITORING DASHBOARD              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Check container status
    echo "📊 CONTAINER STATUS:"
    echo "-------------------"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(metabase|postgres)"
    
    echo ""
    echo "💾 DISK USAGE:"
    echo "-------------"
    du -sh postgres-data metabase1-data metabase2-data backup 2>/dev/null || echo "Some directories not found"
    
    echo ""
    echo "📦 BACKUP STATUS:"
    echo "----------------"
    LATEST_BACKUP=$(ls -t backup/metabase1_*.sql 2>/dev/null | head -1)
    if [ -n "$LATEST_BACKUP" ]; then
        BACKUP_TIME=$(stat -c %y "$LATEST_BACKUP" | cut -d. -f1)
        BACKUP_SIZE=$(du -h "$LATEST_BACKUP" | cut -f1)
        echo "Last backup: $BACKUP_TIME ($BACKUP_SIZE)"
    else
        echo "No backups found"
    fi
    
    echo ""
    echo "🔄 LIVE LOGS (last 5 entries per service):"
    echo "----------------------------------------"
    echo "Metabase1:"
    docker logs --tail 5 metabase1 2>&1 | sed 's/^/  /'
    echo ""
    echo "Metabase2:"
    docker logs --tail 5 metabase2 2>&1 | sed 's/^/  /'
    
    sleep 5
done