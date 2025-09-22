-- scripts/init-db.sql
\echo 'Creating databases and enabling extensions...'

-- Create databases (one by one, ignoring errors if they exist)
CREATE DATABASE n8n_db;
CREATE DATABASE chatwoot_db;
CREATE DATABASE evolution_db;

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE n8n_db TO admin;
GRANT ALL PRIVILEGES ON DATABASE chatwoot_db TO admin;
GRANT ALL PRIVILEGES ON DATABASE evolution_db TO admin;

-- Connect to chatwoot_db and enable vector extension
\c chatwoot_db;
CREATE EXTENSION IF NOT EXISTS vector;
\echo 'Vector extension enabled in chatwoot_db';

-- Connect back to main database
\c automation_db;

\echo 'Database initialization with pgvector complete.';