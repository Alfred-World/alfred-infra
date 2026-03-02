#!/bin/bash
# ============================================
# Auto-create databases for each service
# Called by PostgreSQL on first init only
# ============================================
set -e

echo "🔧 Creating service databases..."

for DB_NAME in alfred_identity alfred_core alfred_notification; do
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<-EOSQL
    SELECT 'CREATE DATABASE ${DB_NAME}'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${DB_NAME}')\gexec
EOSQL
  echo "  ✅ Database '${DB_NAME}' ready"
done

echo "🎉 All databases initialized!"
