from __future__ import annotations

from pydantic import BaseModel, Field


class SyncRulePayload(BaseModel):
    entity: str = Field(min_length=1)
    label: str = Field(min_length=1)
    strategy: str = Field(min_length=1)
    manual_first: bool = True
    reason: str = Field(min_length=1)


class SyncPlanPayload(BaseModel):
    manual_only: bool = True
    supports_auto_sync: bool = False
    rules: list[SyncRulePayload] = Field(default_factory=list)


class ManualSyncRequest(BaseModel):
    account_id: str = Field(min_length=1)
    client_timestamp: str = Field(min_length=1)
    app_version: str = Field(min_length=1)
    plan: SyncPlanPayload


class ManualSyncResponse(BaseModel):
    success: bool = True
    message: str
    synced_entities: int = 0
    conflicts_detected: int = 0
    completed_at: str
    next_step: str
    remote_accepted: bool = True


class IncrementalSyncRequest(BaseModel):
    account_id: str = Field(min_length=1)
    entity: str = Field(min_length=1)
    strategy: str = Field(min_length=1)
    client_timestamp: str = Field(min_length=1)
    app_version: str = Field(min_length=1)
    trigger: str = Field(default='automatic', min_length=1)
    local_cursor: str | None = None
    previous_cursor: str | None = None
    changes_detected: bool = False


class IncrementalSyncResponse(BaseModel):
    success: bool = True
    entity: str
    accepted: bool = True
    changed: bool = False
    conflicts_detected: int = 0
    completed_at: str
    server_cursor: str | None = None
    trigger: str = 'automatic'
    message: str
    remote_accepted: bool = True
