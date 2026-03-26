from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from backend.app.domain.ports import BackupPort, BackupRegistryPort


@dataclass(slots=True)
class BackupUseCases:
    backup: BackupPort
    backup_repo: BackupRegistryPort

    async def create(self, user_id: int) -> tuple[str, Path]:
        return await self.backup.create_backup(user_id)

    async def restore(self, user_id: int, file_bytes: bytes):
        path = await self.backup.restore_backup(file_bytes)
        return await self.backup_repo.create(user_id=user_id, backup_file=str(path))
