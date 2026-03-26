from __future__ import annotations

from pydantic import BaseModel, Field


class SubscriptionStatusResponse(BaseModel):
    plan: str
    status: str
    trial_end: str | None = None
    current_period_end: str | None = None
    features: dict[str, object]


class SubscriptionCheckoutResponse(BaseModel):
    enabled: bool
    checkout_url: str | None = None
    message: str


class SubscriptionWebhookRequest(BaseModel):
    type: str = Field(default="")
    data: dict[str, object] = Field(default_factory=dict)


class SubscriptionWebhookResponse(BaseModel):
    received: bool
    event_type: str
