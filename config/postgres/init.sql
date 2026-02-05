-- PostgreSQL Initialization Script
-- Creates databases for n8n, Chatwoot, and Evolution API
-- Enables pgvector extension for AI/embeddings support

\echo '============================================'
\echo 'Starting database initialization...'
\echo '============================================'

-- Create databases (PostgreSQL will error if they exist, but that's ok in init)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'n8n_db') THEN
        CREATE DATABASE n8n_db;
        RAISE NOTICE 'Database n8n_db created';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'chatwoot_db') THEN
        CREATE DATABASE chatwoot_db;
        RAISE NOTICE 'Database chatwoot_db created';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'evolution_db') THEN
        CREATE DATABASE evolution_db;
        RAISE NOTICE 'Database evolution_db created';
    END IF;
END $$;

-- Grant permissions to admin user
GRANT ALL PRIVILEGES ON DATABASE n8n_db TO admin;
GRANT ALL PRIVILEGES ON DATABASE chatwoot_db TO admin;
GRANT ALL PRIVILEGES ON DATABASE evolution_db TO admin;

\echo 'Permissions granted to admin user'

-- Enable pgvector extension in chatwoot_db (for AI embeddings)
\c chatwoot_db;
CREATE EXTENSION IF NOT EXISTS vector;
\echo 'pgvector extension enabled in chatwoot_db'

-- Return to main database
\c postgres;

\echo '============================================'
\echo 'Database initialization complete!'
\echo '============================================'
