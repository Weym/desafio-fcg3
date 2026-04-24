from functools import lru_cache
from typing import Literal, Self

from pydantic import Field, PostgresDsn, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


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
    jwt_expiration_hours: int = Field(
        default=24,
        ge=1,
        le=168,
        description="JWT expiration time in hours.",
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
        default="",
        description="WhatsApp app secret for webhook signature validation.",
    )

    resend_api_key: str = Field(
        pattern=r"^re_",
        description="Resend API key.",
    )

    llm_provider: Literal["openai", "gemini"] = Field(
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


@lru_cache
def get_settings() -> Settings:
    """Lazily load and cache validated application settings."""

    return Settings()
