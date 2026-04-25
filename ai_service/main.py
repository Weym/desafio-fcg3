"""FastAPI entrypoint for the AI service."""

from __future__ import annotations

from contextlib import asynccontextmanager
from pathlib import Path

import uvicorn
from fastapi import FastAPI, HTTPException, Request, status
from pydantic import BaseModel

from ai_service.config import settings
from ai_service.database import check_db_health, create_pool


class ChatRequest(BaseModel):
    session_id: str
    message: str


def _resolve_prompt_path() -> Path:
    return Path(__file__).resolve().parent / settings.SYSTEM_PROMPT_PATH


@asynccontextmanager
async def lifespan(app: FastAPI):
    pool = create_pool(settings.DATABASE_URL)
    app.state.db_pool = pool
    app.state.system_prompt = _resolve_prompt_path().read_text(encoding="utf-8")

    try:
        yield
    finally:
        pool.close()


app = FastAPI(
    title="AI Service",
    version="0.1.0",
    lifespan=lifespan,
)


@app.get("/health")
async def health_check(request: Request) -> dict[str, str]:
    if not check_db_health(request.app.state.db_pool):
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database unavailable",
        )

    return {"status": "healthy"}


@app.post("/chat", status_code=status.HTTP_501_NOT_IMPLEMENTED)
async def chat(_: ChatRequest) -> dict[str, str]:
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet",
    )


if __name__ == "__main__":
    uvicorn.run("ai_service.main:app", host="0.0.0.0", port=8001, reload=True)
