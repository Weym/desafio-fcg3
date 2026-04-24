#!/bin/bash
set -euo pipefail

: "${POSTGRES_USER:?POSTGRES_USER is required}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}"
: "${POSTGRES_DB:?POSTGRES_DB is required}"

run_psql() {
    PGPASSWORD="${PGPASSWORD:-}" psql \
        -v ON_ERROR_STOP=1 \
        -v reconcile_user="$POSTGRES_USER" \
        -v reconcile_password="$POSTGRES_PASSWORD" \
        -v reconcile_db="$POSTGRES_DB" \
        --username="${POSTGRES_USER:-postgres}" \
        --dbname="$1"
}

run_psql postgres <<'SQL'
SELECT format(
    'CREATE ROLE %I LOGIN PASSWORD %L',
    :'reconcile_user',
    :'reconcile_password'
)
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_roles
    WHERE rolname = :'reconcile_user'
)
\gexec

SELECT format(
    'ALTER ROLE %I WITH LOGIN PASSWORD %L',
    :'reconcile_user',
    :'reconcile_password'
)
\gexec

SELECT format(
    'CREATE DATABASE %I OWNER %I',
    :'reconcile_db',
    :'reconcile_user'
)
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_database
    WHERE datname = :'reconcile_db'
)
\gexec

SELECT format(
    'ALTER DATABASE %I OWNER TO %I',
    :'reconcile_db',
    :'reconcile_user'
)
\gexec

SELECT format(
    'GRANT ALL PRIVILEGES ON DATABASE %I TO %I',
    :'reconcile_db',
    :'reconcile_user'
)
\gexec
SQL

run_psql "$POSTGRES_DB" <<'SQL'
SELECT format(
    'ALTER SCHEMA public OWNER TO %I',
    :'reconcile_user'
)
\gexec

SELECT format(
    'GRANT ALL ON SCHEMA public TO %I',
    :'reconcile_user'
)
\gexec
SQL
