from __future__ import annotations

from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from backend.database.models import Loan


class LoanRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def create(
        self,
        *,
        user_id: int,
        person: str,
        amount: float,
        description: str | None,
        date_value: date,
        deduction_type: str = 'ninguno',
    ) -> Loan:
        item = Loan(
            user_id=user_id,
            person=person,
            amount=amount,
            description=description,
            date=date_value,
            deduction_type=deduction_type,
            is_paid=False,
        )
        self.session.add(item)
        await self.session.flush()
        return item

    async def get_by_id(self, loan_id: int) -> Loan | None:
        return await self.session.get(Loan, loan_id)

    async def list_by_user(self, user_id: int, *, include_paid: bool = False) -> list[Loan]:
        stmt = select(Loan).where(Loan.user_id == user_id)
        if not include_paid:
            stmt = stmt.where(Loan.is_paid.is_(False))
        stmt = stmt.order_by(Loan.date.desc(), Loan.id.desc())
        return list(await self.session.scalars(stmt))

    async def update(
        self,
        loan_id: int,
        *,
        person: str | None = None,
        amount: float | None = None,
        description: str | None = None,
        date_value: date | None = None,
        deduction_type: str | None = None,
        is_paid: bool | None = None,
        paid_date: date | None = None,
    ) -> Loan | None:
        item = await self.get_by_id(loan_id)
        if item is None:
            return None
        if person is not None:
            item.person = person
        if amount is not None:
            item.amount = amount
        if description is not None:
            item.description = description
        if date_value is not None:
            item.date = date_value
        if deduction_type is not None:
            item.deduction_type = deduction_type
        if is_paid is not None:
            item.is_paid = is_paid
        if paid_date is not None or is_paid is False:
            item.paid_date = paid_date
        await self.session.flush()
        return item

    async def delete(self, loan_id: int) -> bool:
        item = await self.get_by_id(loan_id)
        if item is None:
            return False
        await self.session.delete(item)
        await self.session.flush()
        return True
