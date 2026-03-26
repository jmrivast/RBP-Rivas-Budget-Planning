from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Mapping, Protocol


@dataclass(slots=True)
class SubscriptionStatus:
    plan: str
    status: str
    is_premium: bool
    trial_end: datetime | None
    current_period_end: datetime | None
    expense_limit_per_period: int | None
    billing_provider: str = 'stub'


class SubscriptionPort(Protocol):
    async def get_status(self, user_id: int) -> SubscriptionStatus:
        ...

    async def create_checkout(self, user_id: int) -> str | None:
        ...

    async def process_webhook(
        self,
        payload: dict[str, object],
        *,
        raw_body: bytes | None = None,
        headers: Mapping[str, str] | None = None,
    ) -> str:
        ...

    async def can_create_expense(self, user_id: int, period_expense_count: int) -> bool:
        ...


@dataclass(slots=True)
class SubscriptionUseCases:
    subscription: SubscriptionPort

    async def status(self, user_id: int) -> SubscriptionStatus:
        return await self.subscription.get_status(user_id)

    async def checkout(self, user_id: int) -> str | None:
        return await self.subscription.create_checkout(user_id)

    async def webhook(
        self,
        payload: dict[str, object],
        *,
        raw_body: bytes | None = None,
        headers: Mapping[str, str] | None = None,
    ) -> str:
        return await self.subscription.process_webhook(
            payload,
            raw_body=raw_body,
            headers=headers,
        )

    async def can_create_expense(self, user_id: int, period_expense_count: int) -> bool:
        return await self.subscription.can_create_expense(user_id, period_expense_count)
