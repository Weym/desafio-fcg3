from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    database_url: str
    fastapi_base_url: str
    mcp_service_token: str

    def validate_runtime(self) -> None:
        missing = []
        if not self.database_url:
            missing.append("DATABASE_URL")
        if not self.mcp_service_token:
            missing.append("MCP_SERVICE_TOKEN")
        if missing:
            missing_list = ", ".join(missing)
            raise RuntimeError(f"Missing required environment variables: {missing_list}")


settings = Settings(
    database_url=os.environ.get("DATABASE_URL", ""),
    fastapi_base_url=os.environ.get(
        "FASTAPI_BASE_URL",
        "http://fastapi-app:8000/api/v1",
    ),
    mcp_service_token=os.environ.get("MCP_SERVICE_TOKEN", ""),
)
