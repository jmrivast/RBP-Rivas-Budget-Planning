from __future__ import annotations

from datetime import date

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from backend.database.models import ExtraIncome


class IncomeRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def create(
        self,
        *,
        user_id: int,
        amount: float,
        description: str,
        date_value: date,
        income_type: str = "bonus",
    ) -> ExtraIncome:
        income = ExtraIncome(
            user_id=user_id,
            amount=amount,
            description=description,
            date=date_value,
            income_type=income_type,
        )
        self.session.add(income)
        await self.session.flush()
        await self.session.refresh(income)
        return income

    async def get_by_id(self, income_id: int) -> ExtraIncome | None:
        return await self.session.get(ExtraIncome, income_id)

    async def list_by_range(self, user_id: int, start_date: date, end_date: date) -> list[ExtraIncome]:
        stmt = (
            select(ExtraIncome)
            .where(
                ExtraIncome.user_id == user_id,
                ExtraIncome.date >= start_date,
                ExtraIncome.date <= end_date,
            )
            .order_by(ExtraIncome.date.desc(), ExtraIncome.id.desc())
        )
        return list(await self.session.scalars(stmt))

    async def get_total_by_range(self, user_id: int, start_date: date, end_date: date) -> float:
        stmt = select(func.coalesce(func.sum(ExtraIncome.amount), 0)).where(
            ExtraIncome.user_id == user_id,
            ExtraIncome.date >= start_date,
            ExtraIncome.date <= end_date,
        )
        return float(await self.session.scalar(stmt) or 0)

    async def update(
        self,
        income_id: int,
        *,
        amount: float | None = None,
        description: str | None = None,
        date_value: date | None = None,
    ) -> ExtraIncome | None:
        income = await self.get_by_id(income_id)
        if income is None:
            return None
        if amount is not None:
            income.amount = amount
        if description is not None:
            income.description = description
        if date_value is not None:
            income.date = date_value
        await self.session.flush()
        return income

    async def delete(self, income_id: int) -> bool:
        income = await self.get_by_id(income_id)
        if income is None:
            return False
        await self.session.delete(income)
        await self.session.flush()
        return True
