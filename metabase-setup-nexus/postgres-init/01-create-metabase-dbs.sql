-- Create databases for Metabase instances
CREATE DATABASE metabase1;
CREATE DATABASE metabase2;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE metabase1 TO metabase;
GRANT ALL PRIVILEGES ON DATABASE metabase2 TO metabase;
