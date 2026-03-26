from __future__ import annotations

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from backend.database.engine import get_async_session
from backend.middleware import get_auth_use_cases, get_finance_use_cases


def get_db_session(session: AsyncSession = Depends(get_async_session)) -> AsyncSession:
    return session


__all__ = ["get_db_session", "get_auth_use_cases", "get_finance_use_cases"]
