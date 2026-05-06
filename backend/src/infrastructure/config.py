import os
from functools import lru_cache
from typing import Literal, Self
from urllib.parse import quote_plus

from pydantic import Field, PostgresDsn, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


DEFAULT_POSTGRES_DB = "fcg3"
DEFAULT_POSTGRES_HOST = "postgres"
DEFAULT_POSTGRES_PASSWORD = "change_me_in_production"
DEFAULT_POSTGRES_PORT = 5432
DEFAULT_POSTGRES_USER = "fcg3"


def _normalize_database_url(database_url: str, *, driver: str | None) -> str:
    if driver == "sync":
        return database_url.replace("postgresql+asyncpg://", "postgresql://", 1).replace(
            "postgresql+psycopg://",
            "postgresql://",
            1,
        )

    if driver == "asyncpg":
        return database_url.replace("postgresql://", "postgresql+asyncpg://", 1).replace(
            "postgresql+psycopg://",
            "postgresql+asyncpg://",
            1,
        )

    if driver == "psycopg":
        return database_url.replace("postgresql://", "postgresql+psycopg://", 1).replace(
            "postgresql+asyncpg://",
            "postgresql+psycopg://",
            1,
        )

    return database_url


def build_database_url(
    *,
    env_var: str,
    driver: Literal["asyncpg", "psycopg", "sync"],
    fallback_env_var: str | None = None,
) -> str:
    explicit_database_url = os.getenv(env_var)
    if explicit_database_url:
        return _normalize_database_url(explicit_database_url, driver=driver)

    if fallback_env_var:
        fallback_database_url = os.getenv(fallback_env_var)
        if fallback_database_url:
            return _normalize_database_url(fallback_database_url, driver=driver)

    postgres_user = os.getenv("POSTGRES_USER", DEFAULT_POSTGRES_USER)
    postgres_password = os.getenv("POSTGRES_PASSWORD", DEFAULT_POSTGRES_PASSWORD)
    postgres_host = os.getenv("POSTGRES_HOST", DEFAULT_POSTGRES_HOST)
    postgres_port = os.getenv("POSTGRES_PORT", str(DEFAULT_POSTGRES_PORT))
    postgres_db = os.getenv("POSTGRES_DB", DEFAULT_POSTGRES_DB)

    scheme = "postgresql" if driver == "sync" else f"postgresql+{driver}"

    return (
        f"{scheme}://{quote_plus(postgres_user)}:{quote_plus(postgres_password)}"
        f"@{postgres_host}:{postgres_port}/{quote_plus(postgres_db)}"
    )


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    database_url: PostgresDsn = Field(
        description="PostgreSQL connection URL for FastAPI runtime (asyncpg).",
    )
    alembic_database_url: PostgresDsn | None = Field(
        default=None,
        description="PostgreSQL connection URL for Alembic migrations (sync driver).",
    )
    database_url_ai: PostgresDsn | None = Field(
        default=None,
        description="PostgreSQL connection URL for LangChain/PGVector runtime (psycopg).",
    )
    database_url_mcp: PostgresDsn | None = Field(
        default=None,
        description="PostgreSQL connection URL for MCP runtime (asyncpg).",
    )

    jwt_secret: str = Field(
        min_length=16,
        description="Secret key for JWT signing.",
    )
    jwt_algorithm: str = Field(
        default="HS256",
        description="JWT signing algorithm.",
    )
    jwt_access_expiry_seconds: int = Field(
        default=3600,
        description="JWT access token TTL in seconds (D-01: 1 hour).",
    )
    jwt_refresh_expiry_seconds: int = Field(
        default=2592000,
        description="JWT refresh token TTL in seconds (D-01: 30 days).",
    )

    mcp_service_token: str = Field(
        min_length=16,
        description="Internal service token used by MCP to call FastAPI.",
    )
    fastapi_url: str = Field(
        default="http://fastapi-app:8000",
        description="Internal FastAPI base URL used by MCP Server.",
    )

    whatsapp_token: str = Field(
        description="WhatsApp Business Cloud API token.",
    )
    whatsapp_phone_number_id: str = Field(
        description="WhatsApp Business phone number identifier.",
    )
    whatsapp_webhook_verify_token: str = Field(
        description="WhatsApp webhook verification token.",
    )
    whatsapp_app_secret: str = Field(
        min_length=1,
        description="WhatsApp app secret for webhook signature validation (REQUIRED).",
    )
    whatsapp_api_version: str = Field(
        default="v18.0",
        description="WhatsApp Graph API version (MINOR-2: configurable, not hardcoded).",
    )

    ai_service_url: str = Field(
        default="http://langchain-service:8001",
        description="Internal AI service URL for background task processing.",
    )

    resend_api_key: str = Field(
        pattern=r"^re_",
        description="Resend API key.",
    )
    resend_from: str = Field(
        default="Academia <no-reply@test.invalid>",
        description="Resend sender address (e.g. 'Academia <no-reply@domain>').",
    )

    otp_expiry_seconds: int = Field(
        default=300,
        description="OTP code TTL in seconds (SC-1: 5 min).",
    )
    otp_max_attempts: int = Field(
        default=3,
        description="Max wrong OTP attempts before invalidation (SC-3).",
    )
    dev_master_otp: str | None = Field(
        default=None,
        description=(
            "DEV ONLY: if set, this plaintext code is accepted by /auth/verify-code "
            "in place of the real hash check. MUST be unset in production."
        ),
    )

    rate_limit_email: str = Field(
        default="5/15 minutes",
        description="slowapi rate limit string per email (D-13).",
    )
    rate_limit_ip: str = Field(
        default="20/15 minutes",
        description="slowapi rate limit string per IP (D-14).",
    )

    llm_provider: Literal["openai", "gemini", "openrouter"] = Field(
        default="openai",
        description="Configured LLM provider.",
    )
    openai_api_key: str | None = Field(
        default=None,
        description="OpenAI API key.",
    )
    gemini_api_key: str | None = Field(
        default=None,
        description="Google Gemini API key.",
    )
    openrouter_api_key: str | None = Field(
        default=None,
        description="OpenRouter API key.",
    )

    fcm_credentials_path: str | None = Field(
        default=None,
        description="Optional path to the Firebase service account JSON file.",
    )

    @model_validator(mode="after")
    def apply_service_database_defaults(self) -> Self:
        database_url = str(self.database_url)

        if self.alembic_database_url is None:
            self.alembic_database_url = database_url.replace(
                "postgresql+asyncpg://",
                "postgresql://",
                1,
            )

        if self.database_url_mcp is None:
            self.database_url_mcp = database_url

        if self.database_url_ai is None:
            self.database_url_ai = database_url.replace(
                "postgresql+asyncpg://",
                "postgresql+psycopg://",
                1,
            )

        return self

    @model_validator(mode="before")
    @classmethod
    def apply_database_url_defaults(cls, data: object) -> object:
        if not isinstance(data, dict):
            return data

        values = dict(data)
        values.setdefault(
            "database_url",
            build_database_url(env_var="DATABASE_URL", driver="asyncpg"),
        )
        values.setdefault(
            "alembic_database_url",
            build_database_url(
                env_var="ALEMBIC_DATABASE_URL",
                driver="sync",
                fallback_env_var="DATABASE_URL",
            ),
        )
        values.setdefault(
            "database_url_mcp",
            build_database_url(
                env_var="DATABASE_URL_MCP",
                driver="asyncpg",
                fallback_env_var="DATABASE_URL",
            ),
        )
        values.setdefault(
            "database_url_ai",
            build_database_url(
                env_var="DATABASE_URL_AI",
                driver="psycopg",
                fallback_env_var="DATABASE_URL",
            ),
        )
        return values


@lru_cache
def get_settings() -> Settings:
    """Lazily load and cache validated application settings."""

    return Settings()
