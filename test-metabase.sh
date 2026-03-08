#!/bin/bash

echo "🔍 Testing Metabase with PostgreSQL..."

# Test PostgreSQL connection
echo "Testing PostgreSQL connection..."
docker exec postgres-metabase psql -U metabase -d metabase_main -c "SELECT 'PostgreSQL is ready' as status;"

# Test Metabase 1
echo -e "\nTesting Metabase 1..."
curl -s http://localhost:3015/api/health || echo "Metabase 1 still starting..."

# Test Metabase 2
echo -e "\nTesting Metabase 2..."
curl -s http://localhost:3030/api/health || echo "Metabase 2 still starting..."

# Check logs if issues
echo -e "\n📋 Recent Metabase 1 logs:"
docker logs --tail 20 metabase1

echo -e "\n📋 Recent Metabase 2 logs:"
docker logs --tail 20 metabase2