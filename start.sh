#!/bin/bash
set -e

# Enable pgvector extension
echo "Enabling pgvector extension..."
PGPASSWORD=$(echo $DATABASE_URL | sed -n 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/p') \
psql "$DATABASE_URL" -c "CREATE EXTENSION IF NOT EXISTS vector;" 2>/dev/null || true

# Run Prisma migrations
echo "Running database migrations..."
prisma db push --skip-generate

# Start the application
echo "Starting application..."
exec uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}
