from __future__ import annotations

from dataclasses import dataclass
from datetime import date

from backend.app.domain.entities import Loan
from backend.app.domain.ports import FinancePort


@dataclass(slots=True)
class LoansUseCases:
    finance: FinancePort

    async def list(self, *, include_paid: bool = False) -> list[Loan]:
        return await self.finance.list_loans(include_paid=include_paid)

    async def create(
        self,
        *,
        person: str,
        amount: float,
        description: str | None,
        date_value: date,
        deduction_type: str,
    ) -> Loan:
        return await self.finance.add_loan(
            person=person,
            amount=amount,
            description=description,
            date_value=date_value,
            deduction_type=deduction_type,
        )

    async def update(
        self,
        loan_id: int,
        *,
        person: str,
        amount: float,
        description: str | None,
        date_value: date,
        deduction_type: str,
    ) -> Loan:
        return await self.finance.update_loan(
            loan_id,
            person=person,
            amount=amount,
            description=description,
            date_value=date_value,
            deduction_type=deduction_type,
        )

    async def pay(self, loan_id: int) -> Loan:
        return await self.finance.pay_loan(loan_id)

    async def delete(self, loan_id: int) -> None:
        await self.finance.delete_loan(loan_id)
