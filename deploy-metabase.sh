#!/bin/bash

echo "🚀 Starting Metabase deployment with PostgreSQL..."

# Create init directory if it doesn't exist
mkdir -p postgres-init

# Create init SQL script
cat > postgres-init/01-create-metabase-dbs.sql << 'EOF'
-- Create databases for Metabase instances
CREATE DATABASE metabase1;
CREATE DATABASE metabase2;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE metabase1 TO metabase;
GRANT ALL PRIVILEGES ON DATABASE metabase2 TO metabase;
EOF

echo "📦 Starting PostgreSQL container..."
docker compose up -d postgres-metabase

echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 20

# Check if PostgreSQL is ready
until docker exec postgres-metabase pg_isready -U metabase; do
    echo "Waiting for PostgreSQL..."
    sleep 5
done

echo "✅ PostgreSQL is ready!"

# Verify databases were created
echo "📊 Checking databases:"
docker exec postgres-metabase psql -U metabase -d metabase_main -c "\l"

echo "🚀 Starting Metabase instances..."
docker compose up -d metabase1 metabase2

echo "📝 Following logs (Ctrl+C to exit):"
docker compose logs -f metabase1 metabase2