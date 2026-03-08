#!/bin/bash

# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready..."
until docker exec mysql-metabase mysqladmin ping -h localhost --silent; do
    sleep 2
done

# Create databases for Metabase instances
echo "Creating Metabase databases..."
docker exec mysql-metabase mysql -u root -prootpassword123 -e "
CREATE DATABASE IF NOT EXISTS metabase1;
CREATE DATABASE IF NOT EXISTS metabase2;
GRANT ALL PRIVILEGES ON metabase1.* TO 'metabase_user'@'%';
GRANT ALL PRIVILEGES ON metabase2.* TO 'metabase_user'@'%';
FLUSH PRIVILEGES;
"

echo "Databases created successfully!"