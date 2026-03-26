from __future__ import annotations

from pathlib import Path
from typing import Protocol


class ExportPort(Protocol):
    async def build_csv(self, *, year: int, month: int, cycle: int) -> tuple[str, bytes]: ...
    async def build_pdf(self, *, year: int, month: int, cycle: int) -> tuple[str, bytes]: ...


class BackupPort(Protocol):
    async def create_backup(self, user_id: int) -> tuple[str, Path]: ...
    async def restore_backup(self, file_bytes: bytes) -> Path: ...


class BackupRegistryPort(Protocol):
    async def create(self, *, user_id: int, backup_file: str): ...
