FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt requirements-dev.txt ./
RUN pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir -r requirements-dev.txt

COPY alembic.ini ./
COPY alembic/ ./alembic/
# Keep Alembic assets in the image for clean builds; docker-compose bind mounts
# them in dev/UAT so the running fastapi-app cannot drift behind revision 009a.
COPY pyproject.toml ./
COPY tests/ ./tests/
COPY src/ ./src/
COPY scripts/ ./scripts/

EXPOSE 8000

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
