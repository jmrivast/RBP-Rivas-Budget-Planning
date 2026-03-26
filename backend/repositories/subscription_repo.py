from __future__ import annotations

from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from backend.database.models import Subscription


class SubscriptionRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get_by_user(self, user_id: int) -> Subscription | None:
        stmt = (
            select(Subscription)
            .where(Subscription.user_id == user_id)
            .order_by(Subscription.id.desc())
            .limit(1)
        )
        return await self.session.scalar(stmt)

    async def get_by_customer_id(self, customer_id: str) -> Subscription | None:
        stmt = (
            select(Subscription)
            .where(Subscription.stripe_customer_id == customer_id)
            .order_by(Subscription.id.desc())
            .limit(1)
        )
        return await self.session.scalar(stmt)

    async def get_by_subscription_id(self, subscription_id: str) -> Subscription | None:
        stmt = (
            select(Subscription)
            .where(Subscription.stripe_subscription_id == subscription_id)
            .order_by(Subscription.id.desc())
            .limit(1)
        )
        return await self.session.scalar(stmt)


    async def get_by_provider_customer_id(self, customer_id: str) -> Subscription | None:
        return await self.get_by_customer_id(customer_id)

    async def get_by_provider_subscription_id(self, subscription_id: str) -> Subscription | None:
        return await self.get_by_subscription_id(subscription_id)

    async def ensure_default(self, user_id: int) -> Subscription:
        item = await self.get_by_user(user_id)
        if item is not None:
            return item
        now = datetime.now(timezone.utc)
        item = Subscription(
            user_id=user_id,
            plan="free",
            status="trialing",
            trial_end=now + timedelta(days=14),
            current_period_end=now + timedelta(days=14),
        )
        self.session.add(item)
        await self.session.flush()
        return item

    async def update_status(
        self,
        user_id: int,
        *,
        plan: str | None = None,
        status: str | None = None,
        provider_customer_id: str | None = None,
        provider_subscription_id: str | None = None,
        stripe_customer_id: str | None = None,
        stripe_subscription_id: str | None = None,
        trial_end: datetime | None = None,
        current_period_end: datetime | None = None,
    ) -> Subscription:
        item = await self.ensure_default(user_id)
        if plan is not None:
            item.plan = plan
        if status is not None:
            item.status = status
        if provider_customer_id is not None:
            item.stripe_customer_id = provider_customer_id
        elif stripe_customer_id is not None:
            item.stripe_customer_id = stripe_customer_id
        if provider_subscription_id is not None:
            item.stripe_subscription_id = provider_subscription_id
        elif stripe_subscription_id is not None:
            item.stripe_subscription_id = stripe_subscription_id
        if trial_end is not None:
            item.trial_end = trial_end
        if current_period_end is not None:
            item.current_period_end = current_period_end
        await self.session.flush()
        return item
