from __future__ import annotations

from datetime import UTC, date, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from backend.database.models import FixedPayment, FixedPaymentRecord


class FixedPaymentRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def create(
        self,
        *,
        user_id: int,
        name: str,
        amount: float,
        due_day: int,
        category_id: int | None = None,
        frequency: str = "monthly",
    ) -> FixedPayment:
        payment = FixedPayment(
            user_id=user_id,
            name=name,
            amount=amount,
            due_day=due_day,
            category_id=category_id,
            frequency=frequency,
        )
        self.session.add(payment)
        await self.session.flush()
        await self.session.refresh(payment)
        return payment

    async def get_by_id(self, payment_id: int) -> FixedPayment | None:
        return await self.session.get(FixedPayment, payment_id)

    async def list_active_by_user(self, user_id: int) -> list[FixedPayment]:
        stmt = (
            select(FixedPayment)
            .where(FixedPayment.user_id == user_id, FixedPayment.is_active.is_(True))
            .order_by(FixedPayment.due_day.asc(), FixedPayment.name.asc())
        )
        return list(await self.session.scalars(stmt))

    async def update(
        self,
        payment_id: int,
        *,
        name: str | None = None,
        amount: float | None = None,
        due_day: int | None = None,
        category_id: int | None = None,
        update_category: bool = False,
    ) -> FixedPayment | None:
        payment = await self.get_by_id(payment_id)
        if payment is None:
            return None
        if name is not None:
            payment.name = name
        if amount is not None:
            payment.amount = amount
        if due_day is not None:
            payment.due_day = due_day
        if update_category or category_id is not None:
            payment.category_id = category_id
        payment.updated_at = datetime.now(UTC).replace(tzinfo=None)
        await self.session.flush()
        return payment

    async def soft_delete(self, payment_id: int) -> bool:
        payment = await self.get_by_id(payment_id)
        if payment is None:
            return False
        payment.is_active = False
        payment.updated_at = datetime.now(UTC).replace(tzinfo=None)
        await self.session.flush()
        return True

    async def get_latest_record(
        self,
        fixed_payment_id: int,
        year: int,
        month: int,
        cycle: int,
    ) -> FixedPaymentRecord | None:
        stmt = (
            select(FixedPaymentRecord)
            .where(
                FixedPaymentRecord.fixed_payment_id == fixed_payment_id,
                FixedPaymentRecord.year == year,
                FixedPaymentRecord.month == month,
                FixedPaymentRecord.quincenal_cycle == cycle,
            )
            .order_by(FixedPaymentRecord.id.desc())
            .limit(1)
        )
        return await self.session.scalar(stmt)

    async def get_record_status(
        self,
        fixed_payment_id: int,
        year: int,
        month: int,
        cycle: int,
        *,
        default_status: str = "pending",
    ) -> str:
        record = await self.get_latest_record(fixed_payment_id, year, month, cycle)
        if record is None or not record.status:
            return default_status
        return record.status.strip().lower()

    async def set_record_status(
        self,
        fixed_payment_id: int,
        year: int,
        month: int,
        cycle: int,
        paid: bool,
    ) -> FixedPaymentRecord:
        record = await self.get_latest_record(fixed_payment_id, year, month, cycle)
        paid_date = date.today() if paid else None
        status = "paid" if paid else "pending"
        if record is None:
            record = FixedPaymentRecord(
                fixed_payment_id=fixed_payment_id,
                year=year,
                month=month,
                quincenal_cycle=cycle,
                status=status,
                paid_date=paid_date,
            )
            self.session.add(record)
        else:
            record.status = status
            record.paid_date = paid_date
        await self.session.flush()
        await self.session.refresh(record)
        return record

    async def count_active_category_usage(self, category_id: int) -> int:
        stmt = (
            select(FixedPayment.id)
            .where(FixedPayment.category_id == category_id, FixedPayment.is_active.is_(True))
        )
        return len(list(await self.session.scalars(stmt)))
