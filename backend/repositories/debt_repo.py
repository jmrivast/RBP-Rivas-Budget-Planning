from __future__ import annotations

from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from backend.database.models import Debt, DebtPayment, PersonalDebt, PersonalDebtPayment


class DebtRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def create_debt(
        self,
        *,
        user_id: int,
        name: str,
        principal_amount: float,
        annual_rate: float,
        term_months: int,
        start_date: date,
        payment_day: int,
        monthly_payment: float,
        current_balance: float | None = None,
    ) -> Debt:
        item = Debt(
            user_id=user_id,
            name=name,
            principal_amount=principal_amount,
            annual_rate=annual_rate,
            term_months=term_months,
            start_date=start_date,
            payment_day=payment_day,
            monthly_payment=monthly_payment,
            current_balance=principal_amount if current_balance is None else current_balance,
            is_active=True,
        )
        self.session.add(item)
        await self.session.flush()
        return item

    async def get_debt(self, debt_id: int) -> Debt | None:
        stmt = select(Debt).options(selectinload(Debt.payments)).where(Debt.id == debt_id).limit(1)
        return await self.session.scalar(stmt)

    async def list_debts(self, user_id: int, *, include_inactive: bool = False) -> list[Debt]:
        stmt = select(Debt).options(selectinload(Debt.payments)).where(Debt.user_id == user_id)
        if not include_inactive:
            stmt = stmt.where(Debt.is_active.is_(True))
        stmt = stmt.order_by(Debt.start_date.desc(), Debt.id.desc())
        return list(await self.session.scalars(stmt))

    async def update_debt(
        self,
        debt_id: int,
        *,
        name: str | None = None,
        principal_amount: float | None = None,
        annual_rate: float | None = None,
        term_months: int | None = None,
        start_date: date | None = None,
        payment_day: int | None = None,
        monthly_payment: float | None = None,
        current_balance: float | None = None,
        is_active: bool | None = None,
    ) -> Debt | None:
        item = await self.get_debt(debt_id)
        if item is None:
            return None
        if name is not None:
            item.name = name
        if principal_amount is not None:
            item.principal_amount = principal_amount
        if annual_rate is not None:
            item.annual_rate = annual_rate
        if term_months is not None:
            item.term_months = term_months
        if start_date is not None:
            item.start_date = start_date
        if payment_day is not None:
            item.payment_day = payment_day
        if monthly_payment is not None:
            item.monthly_payment = monthly_payment
        if current_balance is not None:
            item.current_balance = current_balance
        if is_active is not None:
            item.is_active = is_active
        await self.session.flush()
        return item

    async def create_debt_payment(
        self,
        *,
        debt_id: int,
        payment_date: date,
        total_amount: float,
        interest_amount: float,
        capital_amount: float,
        notes: str | None,
    ) -> DebtPayment:
        item = DebtPayment(
            debt_id=debt_id,
            payment_date=payment_date,
            total_amount=total_amount,
            interest_amount=interest_amount,
            capital_amount=capital_amount,
            notes=notes,
        )
        self.session.add(item)
        await self.session.flush()
        return item

    async def list_debt_payments(self, debt_id: int) -> list[DebtPayment]:
        stmt = select(DebtPayment).where(DebtPayment.debt_id == debt_id).order_by(DebtPayment.payment_date.desc(), DebtPayment.id.desc())
        return list(await self.session.scalars(stmt))

    async def delete_debt(self, debt_id: int) -> bool:
        item = await self.get_debt(debt_id)
        if item is None:
            return False
        await self.session.delete(item)
        await self.session.flush()
        return True

    async def create_personal_debt(
        self,
        *,
        user_id: int,
        person: str,
        total_amount: float,
        current_balance: float | None = None,
        description: str | None,
        date_value: date,
    ) -> PersonalDebt:
        item = PersonalDebt(
            user_id=user_id,
            person=person,
            total_amount=total_amount,
            current_balance=total_amount if current_balance is None else current_balance,
            description=description,
            date=date_value,
            is_paid=False,
        )
        self.session.add(item)
        await self.session.flush()
        return item

    async def get_personal_debt(self, debt_id: int) -> PersonalDebt | None:
        stmt = select(PersonalDebt).options(selectinload(PersonalDebt.payments)).where(PersonalDebt.id == debt_id).limit(1)
        return await self.session.scalar(stmt)

    async def list_personal_debts(self, user_id: int, *, include_paid: bool = False) -> list[PersonalDebt]:
        stmt = select(PersonalDebt).options(selectinload(PersonalDebt.payments)).where(PersonalDebt.user_id == user_id)
        if not include_paid:
            stmt = stmt.where(PersonalDebt.is_paid.is_(False))
        stmt = stmt.order_by(PersonalDebt.date.desc(), PersonalDebt.id.desc())
        return list(await self.session.scalars(stmt))

    async def update_personal_debt(
        self,
        debt_id: int,
        *,
        person: str | None = None,
        total_amount: float | None = None,
        current_balance: float | None = None,
        description: str | None = None,
        date_value: date | None = None,
        is_paid: bool | None = None,
        paid_date: date | None = None,
    ) -> PersonalDebt | None:
        item = await self.get_personal_debt(debt_id)
        if item is None:
            return None
        if person is not None:
            item.person = person
        if total_amount is not None:
            item.total_amount = total_amount
        if current_balance is not None:
            item.current_balance = current_balance
        if description is not None:
            item.description = description
        if date_value is not None:
            item.date = date_value
        if is_paid is not None:
            item.is_paid = is_paid
        if paid_date is not None or is_paid is False:
            item.paid_date = paid_date
        await self.session.flush()
        return item

    async def create_personal_debt_payment(
        self,
        *,
        personal_debt_id: int,
        payment_date: date,
        amount: float,
        notes: str | None,
    ) -> PersonalDebtPayment:
        item = PersonalDebtPayment(
            personal_debt_id=personal_debt_id,
            payment_date=payment_date,
            amount=amount,
            notes=notes,
        )
        self.session.add(item)
        await self.session.flush()
        return item

    async def list_personal_debt_payments(self, debt_id: int) -> list[PersonalDebtPayment]:
        stmt = select(PersonalDebtPayment).where(PersonalDebtPayment.personal_debt_id == debt_id).order_by(PersonalDebtPayment.payment_date.desc(), PersonalDebtPayment.id.desc())
        return list(await self.session.scalars(stmt))

    async def delete_personal_debt(self, debt_id: int) -> bool:
        item = await self.get_personal_debt(debt_id)
        if item is None:
            return False
        await self.session.delete(item)
        await self.session.flush()
        return True
