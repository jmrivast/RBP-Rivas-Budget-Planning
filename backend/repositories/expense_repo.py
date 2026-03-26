from __future__ import annotations

from datetime import date

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from backend.database.models import Expense, ExpenseCategory


class ExpenseRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def create(
        self,
        *,
        user_id: int,
        amount: float,
        description: str,
        date_value: date,
        quincenal_cycle: int,
        category_ids: list[int],
        status: str = "pending",
    ) -> Expense:
        expense = Expense(
            user_id=user_id,
            amount=amount,
            description=description,
            date=date_value,
            quincenal_cycle=quincenal_cycle,
            status=status,
        )
        self.session.add(expense)
        await self.session.flush()
        for category_id in category_ids:
            self.session.add(ExpenseCategory(expense_id=expense.id, category_id=category_id))
        await self.session.flush()
        return await self.get_by_id(expense.id)

    async def list_by_range(
        self,
        user_id: int,
        start_date: date,
        end_date: date,
    ) -> list[Expense]:
        stmt = (
            select(Expense)
            .options(
                selectinload(Expense.categories),
                selectinload(Expense.expense_categories).selectinload(ExpenseCategory.category),
            )
            .where(
                Expense.user_id == user_id,
                Expense.date >= start_date,
                Expense.date <= end_date,
            )
            .order_by(Expense.date.desc(), Expense.id.desc())
        )
        return list(await self.session.scalars(stmt))

    async def get_by_id(self, expense_id: int) -> Expense | None:
        stmt = (
            select(Expense)
            .options(
                selectinload(Expense.categories),
                selectinload(Expense.expense_categories).selectinload(ExpenseCategory.category),
            )
            .where(Expense.id == expense_id)
            .limit(1)
        )
        return await self.session.scalar(stmt)

    async def update(
        self,
        expense_id: int,
        *,
        amount: float | None = None,
        description: str | None = None,
        date_value: date | None = None,
        quincenal_cycle: int | None = None,
        status: str | None = None,
        category_ids: list[int] | None = None,
    ) -> Expense | None:
        expense = await self.get_by_id(expense_id)
        if expense is None:
            return None
        if amount is not None:
            expense.amount = amount
        if description is not None:
            expense.description = description
        if date_value is not None:
            expense.date = date_value
        if quincenal_cycle is not None:
            expense.quincenal_cycle = quincenal_cycle
        if status is not None:
            expense.status = status
        if category_ids is not None:
            expense.expense_categories.clear()
            await self.session.flush()
            for category_id in category_ids:
                expense.expense_categories.append(ExpenseCategory(category_id=category_id))
        await self.session.flush()
        return await self.get_by_id(expense_id)

    async def delete(self, expense_id: int) -> bool:
        expense = await self.get_by_id(expense_id)
        if expense is None:
            return False
        await self.session.delete(expense)
        await self.session.flush()
        return True

    async def count_category_usage(self, category_id: int) -> int:
        stmt = select(func.count()).select_from(ExpenseCategory).where(
            ExpenseCategory.category_id == category_id
        )
        return int(await self.session.scalar(stmt) or 0)

