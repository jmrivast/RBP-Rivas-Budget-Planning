from __future__ import annotations

from dataclasses import dataclass
from datetime import date

from backend.app.domain.entities import Expense
from backend.app.domain.ports import FinancePort


@dataclass(slots=True)
class ExpensesUseCases:
    finance: FinancePort

    async def list(self, start_date: date, end_date: date) -> list[Expense]:
        return await self.finance.list_expenses(start_date, end_date)

    async def create(
        self,
        *,
        amount: float,
        description: str,
        category_id: int,
        date_value: date,
        source: str = "sueldo",
    ) -> Expense:
        return await self.finance.add_expense(
            amount=amount,
            description=description,
            category_id=category_id,
            date_value=date_value,
            source=source,
        )

    async def update(
        self,
        expense_id: int,
        *,
        amount: float,
        description: str,
        category_id: int,
        date_value: date,
    ) -> Expense:
        return await self.finance.update_expense(
            expense_id,
            amount=amount,
            description=description,
            category_id=category_id,
            date_value=date_value,
        )

    async def delete(self, expense_id: int) -> None:
        await self.finance.delete_expense(expense_id)
