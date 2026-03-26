from __future__ import annotations

import shutil
from datetime import datetime
from pathlib import Path

from backend.config import get_settings
from backend.repositories.backup_repo import BackupRepository


class BackupService:
    def __init__(self, backup_repo: BackupRepository) -> None:
        self.backup_repo = backup_repo
        self.settings = get_settings()

    def _db_path(self) -> Path:
        url = self.settings.database_url
        if not url.startswith('sqlite'):
            raise ValueError('Backup solo soporta SQLite por ahora.')
        raw = url.split('///', 1)[-1]
        return Path(raw)

    async def create_backup(self, user_id: int) -> tuple[str, Path]:
        source = self._db_path()
        if not source.exists():
            raise FileNotFoundError('La base de datos SQLite no existe todavia.')
        out_dir = Path('backups')
        out_dir.mkdir(parents=True, exist_ok=True)
        filename = f'finanzas_backup_{datetime.now().strftime("%Y%m%d_%H%M%S")}.db'
        target = out_dir / filename
        shutil.copy2(source, target)
        await self.backup_repo.create(user_id=user_id, backup_file=str(target))
        return filename, target

    async def restore_backup(self, file_bytes: bytes) -> Path:
        if not file_bytes:
            raise ValueError('El archivo de backup esta vacio.')
        source = self._db_path()
        source.parent.mkdir(parents=True, exist_ok=True)
        source.write_bytes(file_bytes)
        return source
