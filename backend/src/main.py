from fastapi import FastAPI
from slowapi.errors import RateLimitExceeded

from src.infrastructure.config import get_settings  # noqa: F401
from src.shared.rate_limit import limiter, rate_limit_exceeded_handler
from src.features.auth.routes import router as auth_router


app = FastAPI(title="Desafio FCG3 - API", version="0.1.0")

# Rate limiting — slowapi
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, rate_limit_exceeded_handler)

# Routers
app.include_router(auth_router)


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
