from __future__ import annotations

from dataclasses import dataclass
from datetime import date

from backend.app.domain.entities import Income
from backend.app.domain.ports import FinancePort


@dataclass(slots=True)
class IncomeUseCases:
    finance: FinancePort

    async def get_salary(
        self,
        *,
        year: int | None = None,
        month: int | None = None,
        cycle: int | None = None,
    ) -> tuple[float, float | None, float]:
        base = await self.finance.get_salary()
        if year is None or month is None or cycle is None:
            return base, None, base
        override = await self.finance.get_salary_override(year, month, cycle)
        return base, override, override if override is not None else base

    async def set_salary(self, amount: float) -> float:
        return await self.finance.set_salary(amount)

    async def set_salary_override(self, year: int, month: int, cycle: int, amount: float) -> float:
        return await self.finance.set_salary_override(year, month, cycle, amount)

    async def delete_salary_override(self, year: int, month: int, cycle: int) -> None:
        await self.finance.delete_salary_override(year, month, cycle)

    async def list(self, start_date: date, end_date: date) -> list[Income]:
        return await self.finance.list_income(start_date, end_date)

    async def create(self, *, amount: float, description: str, date_value: date) -> Income:
        return await self.finance.add_income(amount=amount, description=description, date_value=date_value)

    async def update(
        self,
        income_id: int,
        *,
        amount: float,
        description: str,
        date_value: date,
    ) -> Income:
        return await self.finance.update_income(
            income_id,
            amount=amount,
            description=description,
            date_value=date_value,
        )

    async def delete(self, income_id: int) -> None:
        await self.finance.delete_income(income_id)
