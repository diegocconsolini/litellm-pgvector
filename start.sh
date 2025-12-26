#!/bin/bash
set -e

echo "Initializing database..."

# Create tables using raw SQL (safe for shared database)
psql "$DATABASE_URL" <<'SQL'
-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create vector_stores table if not exists
CREATE TABLE IF NOT EXISTS vector_stores (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name TEXT NOT NULL,
    file_counts JSONB DEFAULT '{"in_progress": 0, "completed": 0, "failed": 0, "cancelled": 0, "total": 0}',
    status TEXT DEFAULT 'completed',
    usage_bytes INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    expires_after JSONB,
    expires_at TIMESTAMP,
    last_active_at TIMESTAMP,
    metadata JSONB DEFAULT '{}'
);

-- Create embeddings table if not exists
CREATE TABLE IF NOT EXISTS embeddings (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    vector_store_id TEXT NOT NULL REFERENCES vector_stores(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    embedding vector(1536),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create index for vector similarity search
CREATE INDEX IF NOT EXISTS embeddings_embedding_idx ON embeddings USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
SQL

echo "Database initialized successfully"

# Debug: Show embedding config
echo "Embedding config:"
echo "  MODEL: ${EMBEDDING__MODEL:-text-embedding-ada-002}"
echo "  BASE_URL: ${EMBEDDING__BASE_URL:-not set}"
echo "  API_KEY: ${EMBEDDING__API_KEY:0:10}..."

# Start the application
echo "Starting application..."
exec uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}
