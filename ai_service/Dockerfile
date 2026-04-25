FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app/ai_service

ENV PYTHONPATH=/app

EXPOSE 8001

CMD ["uvicorn", "ai_service.main:app", "--host", "0.0.0.0", "--port", "8001", "--reload"]
