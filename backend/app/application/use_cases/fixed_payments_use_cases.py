from __future__ import annotations

from dataclasses import dataclass

from backend.app.domain.entities import FixedPayment, FixedPaymentStatus
from backend.app.domain.ports import FinancePort


@dataclass(slots=True)
class FixedPaymentsUseCases:
    finance: FinancePort

    async def list_for_period(self, year: int, month: int, cycle: int) -> list[FixedPaymentStatus]:
        return await self.finance.get_fixed_payments_for_period(year, month, cycle)

    async def create(
        self,
        *,
        name: str,
        amount: float,
        due_day: int,
        category_id: int | None,
        no_fixed_date: bool = False,
    ) -> FixedPayment:
        return await self.finance.add_fixed_payment(
            name=name,
            amount=amount,
            due_day=due_day,
            category_id=category_id,
            no_fixed_date=no_fixed_date,
        )

    async def update(
        self,
        payment_id: int,
        *,
        name: str,
        amount: float,
        due_day: int,
        category_id: int | None,
        no_fixed_date: bool = False,
    ) -> FixedPayment:
        return await self.finance.update_fixed_payment(
            payment_id,
            name=name,
            amount=amount,
            due_day=due_day,
            category_id=category_id,
            no_fixed_date=no_fixed_date,
        )

    async def toggle(
        self,
        payment_id: int,
        *,
        year: int,
        month: int,
        cycle: int,
        paid: bool,
    ) -> FixedPaymentStatus:
        return await self.finance.set_fixed_payment_paid(
            payment_id,
            year,
            month,
            cycle,
            paid,
        )

    async def delete(self, payment_id: int) -> None:
        await self.finance.delete_fixed_payment(payment_id)
