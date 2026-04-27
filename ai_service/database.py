"""Database helpers for AI service chat persistence."""

from __future__ import annotations

from typing import Any


def normalize_psycopg_dsn(dsn: str) -> str:
    """Convert SQLAlchemy-style PostgreSQL URLs into psycopg conninfo URLs."""

    return dsn.replace("postgresql+asyncpg://", "postgresql://", 1).replace(
        "postgresql+psycopg://",
        "postgresql://",
        1,
    )


def create_pool(dsn: str) -> Any:
    """Create a psycopg3 synchronous connection pool."""

    from psycopg_pool import ConnectionPool

    return ConnectionPool(conninfo=normalize_psycopg_dsn(dsn), min_size=2, max_size=10)


def load_chat_history(pool: Any, session_id: str, k: int = 20) -> list[Any]:
    """Load the most recent chat messages in chronological order."""

    from langchain_core.messages import AIMessage, HumanMessage, SystemMessage

    query = (
        "SELECT role, content FROM chat_messages "
        "WHERE chat_session_id = %s "
        "ORDER BY created_at DESC LIMIT %s"
    )

    with pool.connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(query, (session_id, k))
            rows = cursor.fetchall()

    messages: list[Any] = []
    for role, content in reversed(rows):
        if role == "user":
            messages.append(HumanMessage(content=content))
        elif role == "assistant":
            messages.append(AIMessage(content=content))
        elif role == "system":
            messages.append(SystemMessage(content=content))

    return messages


def save_chat_message(pool: Any, session_id: str, role: str, content: str) -> None:
    """Persist a chat message for a session."""

    query = (
        "INSERT INTO chat_messages (id, chat_session_id, role, content) "
        "VALUES (gen_random_uuid(), %s, %s, %s)"
    )

    with pool.connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(query, (session_id, role, content))
        connection.commit()


def check_db_health(pool: Any) -> bool:
    """Return True when the database is reachable."""

    try:
        with pool.connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                cursor.fetchone()
        return True
    except Exception:
        return False
