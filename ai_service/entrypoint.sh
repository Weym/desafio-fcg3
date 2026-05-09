#!/bin/bash
set -eu

echo "[entrypoint] Running RAG knowledge base ingest..."

# Run ingest — failure is non-fatal (service starts regardless)
python -m ai_service.ingest --source /app/ai_service/knowledge 2>&1 || {
    echo "[entrypoint] WARNING: RAG ingest failed (database may not be ready or missing tables). Service will start anyway."
}

echo "[entrypoint] Starting AI service..."
exec python -m ai_service.main
