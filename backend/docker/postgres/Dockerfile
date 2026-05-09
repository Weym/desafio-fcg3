FROM pgvector/pgvector:pg16

RUN apt-get update \
    && apt-get install -y --no-install-recommends postgresql-16-cron \
    && rm -rf /var/lib/apt/lists/*

# Custom pg_hba: trust for local (Unix socket), scram-sha-256 for TCP.
# This ensures reconcile_dev_credentials.sh can always connect locally
# to fix password drift, regardless of the volume state.
COPY pg_hba_custom.conf /etc/postgresql/pg_hba_custom.conf
