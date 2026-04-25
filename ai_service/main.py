"""FastAPI entrypoint for the AI service."""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager
from pathlib import Path

import uvicorn
from fastapi import FastAPI, HTTPException, Request, status
from pydantic import BaseModel

from ai_service.agent import invoke_agent
from ai_service.config import settings
from ai_service.database import check_db_health, create_pool, save_chat_message

logger = logging.getLogger(__name__)


class ChatRequest(BaseModel):
    session_id: str
    message: str


class ChatResponse(BaseModel):
    response: str
    session_id: str


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


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest) -> ChatResponse:
    """Process a student message through the AI agent."""

    try:
        response_text = await invoke_agent(
            settings=settings,
            db_pool=app.state.db_pool,
            system_prompt=app.state.system_prompt,
            session_id=request.session_id,
            user_message=request.message,
        )

        save_chat_message(
            pool=app.state.db_pool,
            session_id=request.session_id,
            role="assistant",
            content=response_text,
        )

        return ChatResponse(
            response=response_text,
            session_id=request.session_id,
        )
    except Exception:
        logger.exception("Chat error for session %s", request.session_id)
        fallback = (
            "Desculpe, estou com dificuldades tecnicas. "
            "Tente novamente em alguns minutos."
        )

        try:
            save_chat_message(
                pool=app.state.db_pool,
                session_id=request.session_id,
                role="assistant",
                content=fallback,
            )
        except Exception:
            logger.exception(
                "Failed to persist fallback response for session %s",
                request.session_id,
            )

        return ChatResponse(
            response=fallback,
            session_id=request.session_id,
        )


if __name__ == "__main__":
    uvicorn.run("ai_service.main:app", host="0.0.0.0", port=8001, reload=True)
