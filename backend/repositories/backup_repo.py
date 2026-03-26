from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from backend.database.models import Backup


class BackupRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def create(self, *, user_id: int, backup_file: str) -> Backup:
        item = Backup(user_id=user_id, backup_file=backup_file)
        self.session.add(item)
        await self.session.flush()
        return item

    async def list_by_user(self, user_id: int) -> list[Backup]:
        stmt = select(Backup).where(Backup.user_id == user_id).order_by(Backup.backup_date.desc(), Backup.id.desc())
        return list(await self.session.scalars(stmt))
