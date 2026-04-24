from fastapi import FastAPI

from infrastructure.config import get_settings  # noqa: F401


app = FastAPI(title="Desafio FCG3 - API", version="0.1.0")


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
