from fastapi import FastAPI


app = FastAPI(title="MCP Server - Stub", version="0.1.0")


@app.get("/health")
async def health_check() -> dict[str, str]:
    return {
        "status": "ok",
        "service": "mcp-server",
        "phase": "stub",
    }
