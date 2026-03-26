from __future__ import annotations

from dataclasses import dataclass
from datetime import date

from backend.app.domain.entities import Debt, DebtPayment, PersonalDebt, PersonalDebtPayment
from backend.app.domain.ports import FinancePort


@dataclass(slots=True)
class DebtsUseCases:
    finance: FinancePort

    async def list(self, *, include_inactive: bool = False) -> list[Debt]:
        return await self.finance.list_debts(include_inactive=include_inactive)

    async def create(
        self,
        *,
        name: str,
        principal_amount: float,
        annual_rate: float,
        term_months: int,
        start_date: date,
        payment_day: int,
    ) -> Debt:
        return await self.finance.create_debt(
            name=name,
            principal_amount=principal_amount,
            annual_rate=annual_rate,
            term_months=term_months,
            start_date=start_date,
            payment_day=payment_day,
        )

    async def update(
        self,
        debt_id: int,
        *,
        name: str,
        principal_amount: float,
        annual_rate: float,
        term_months: int,
        start_date: date,
        payment_day: int,
    ) -> Debt:
        return await self.finance.update_debt(
            debt_id,
            name=name,
            principal_amount=principal_amount,
            annual_rate=annual_rate,
            term_months=term_months,
            start_date=start_date,
            payment_day=payment_day,
        )

    async def delete(self, debt_id: int) -> None:
        await self.finance.delete_debt(debt_id)

    async def add_payment(
        self,
        debt_id: int,
        *,
        payment_date: date,
        total_amount: float,
        interest_amount: float,
        capital_amount: float,
        notes: str | None,
    ) -> DebtPayment:
        return await self.finance.add_debt_payment(
            debt_id,
            payment_date=payment_date,
            total_amount=total_amount,
            interest_amount=interest_amount,
            capital_amount=capital_amount,
            notes=notes,
        )

    async def list_payments(self, debt_id: int) -> list[DebtPayment]:
        return await self.finance.list_debt_payments(debt_id)


@dataclass(slots=True)
class PersonalDebtsUseCases:
    finance: FinancePort

    async def list(self, *, include_paid: bool = False) -> list[PersonalDebt]:
        return await self.finance.list_personal_debts(include_paid=include_paid)

    async def create(
        self,
        *,
        person: str,
        total_amount: float,
        description: str | None,
        date_value: date,
    ) -> PersonalDebt:
        return await self.finance.create_personal_debt(
            person=person,
            total_amount=total_amount,
            description=description,
            date_value=date_value,
        )

    async def update(
        self,
        debt_id: int,
        *,
        person: str,
        total_amount: float,
        description: str | None,
        date_value: date,
    ) -> PersonalDebt:
        return await self.finance.update_personal_debt(
            debt_id,
            person=person,
            total_amount=total_amount,
            description=description,
            date_value=date_value,
        )

    async def delete(self, debt_id: int) -> None:
        await self.finance.delete_personal_debt(debt_id)

    async def add_payment(
        self,
        debt_id: int,
        *,
        payment_date: date,
        amount: float,
        notes: str | None,
    ) -> PersonalDebtPayment:
        return await self.finance.add_personal_debt_payment(
            debt_id,
            payment_date=payment_date,
            amount=amount,
            notes=notes,
        )

    async def list_payments(self, debt_id: int) -> list[PersonalDebtPayment]:
        return await self.finance.list_personal_debt_payments(debt_id)
