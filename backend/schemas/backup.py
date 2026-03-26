from __future__ import annotations

from pydantic import BaseModel, Field


class BackupCreateResponse(BaseModel):
    backup_file: str
    path: str


class BackupItem(BaseModel):
    id: str
    backup_file: str
    backup_date: str


class BackupRestoreRequest(BaseModel):
    backup_file: str = Field(min_length=1)


class BackupRestoreResponse(BaseModel):
    restored_from: str
    database: str
