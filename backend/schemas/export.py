from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel


class ExportInfo(BaseModel):
    filename: str
    content_type: str
    generated_at: datetime


class BackupRead(BaseModel):
    id: int
    user_id: int
    backup_file: str
    backup_date: datetime


class SubscriptionStatusRead(BaseModel):
    plan: str
    status: str
    is_premium: bool
    trial_end: datetime | None = None
    current_period_end: datetime | None = None
    expense_limit_per_period: int | None = None
    billing_provider: str = 'stub'


class CheckoutResponse(BaseModel):
    checkout_url: str | None = None
    message: str


class WebhookResponse(BaseModel):
    ok: bool
    message: str
