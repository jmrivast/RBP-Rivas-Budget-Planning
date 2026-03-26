from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from backend.app.domain.ports import BackupPort, BackupRegistryPort, ExportPort


@dataclass(slots=True)
class ExportBackupUseCases:
    export_service: ExportPort
    backup_service: BackupPort
    backup_repo: BackupRegistryPort

    async def export_csv(self, *, year: int, month: int, cycle: int) -> tuple[str, bytes]:
        return await self.export_service.build_csv(year=year, month=month, cycle=cycle)

    async def export_pdf(self, *, year: int, month: int, cycle: int) -> tuple[str, bytes]:
        return await self.export_service.build_pdf(year=year, month=month, cycle=cycle)

    async def create_backup(self, user_id: int) -> tuple[str, Path]:
        return await self.backup_service.create_backup(user_id)

    async def restore_backup(self, file_bytes: bytes) -> Path:
        return await self.backup_service.restore_backup(file_bytes)

    async def register_backup(self, *, user_id: int, backup_file: str):
        return await self.backup_repo.create(user_id=user_id, backup_file=backup_file)

    async def restore_and_register(self, *, file_bytes: bytes, user_id: int):
        restored_path = await self.restore_backup(file_bytes)
        row = await self.register_backup(user_id=user_id, backup_file=str(restored_path))
        return restored_path, row
