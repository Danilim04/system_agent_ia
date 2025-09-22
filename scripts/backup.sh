#!/bin/bash
# scripts/backup.sh

BACKUP_DIR="/backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

echo "🔄 Creating backup..."

# Backup PostgreSQL databases
docker-compose exec postgres pg_dump -U admin n8n_db > $BACKUP_DIR/n8n_db.sql
docker-compose exec postgres pg_dump -U admin chatwoot_db > $BACKUP_DIR/chatwoot_db.sql
docker-compose exec postgres pg_dump -U admin evolution_db > $BACKUP_DIR/evolution_db.sql

# Backup volumes
docker run --rm -v $(pwd)_n8n_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/n8n_data.tar.gz /data
docker run --rm -v $(pwd)_chatwoot_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/chatwoot_data.tar.gz /data
docker run --rm -v $(pwd)_evolution_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/evolution_data.tar.gz /data

# Backup environment and compose files
cp .env $BACKUP_DIR/
cp docker-compose.yml $BACKUP_DIR/

echo "✅ Backup completed: $BACKUP_DIR"