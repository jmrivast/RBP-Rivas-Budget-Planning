from __future__ import annotations

from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from backend.database.models import Savings, SavingsGoal


class SavingsRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get_latest_entry(self, user_id: int) -> Savings | None:
        stmt = (
            select(Savings)
            .where(Savings.user_id == user_id)
            .order_by(Savings.created_at.desc(), Savings.id.desc())
            .limit(1)
        )
        return await self.session.scalar(stmt)

    async def get_by_period(self, user_id: int, year: int, month: int, cycle: int) -> Savings | None:
        stmt = (
            select(Savings)
            .where(
                Savings.user_id == user_id,
                Savings.year == year,
                Savings.month == month,
                Savings.quincenal_cycle == cycle,
            )
            .limit(1)
        )
        return await self.session.scalar(stmt)

    async def record_savings(
        self,
        user_id: int,
        amount: float,
        year: int,
        month: int,
        cycle: int,
    ) -> Savings:
        current_total = await self.get_total_savings(user_id)
        entry = await self.get_by_period(user_id, year, month, cycle)
        if entry is None:
            entry = Savings(
                user_id=user_id,
                year=year,
                month=month,
                quincenal_cycle=cycle,
            )
            self.session.add(entry)
        entry.last_quincenal_savings = amount
        entry.total_saved = current_total + amount
        entry.updated_at = datetime.now(UTC).replace(tzinfo=None)
        await self.session.flush()
        await self.session.refresh(entry)
        return entry

    async def add_extra_savings(
        self,
        user_id: int,
        amount: float,
        year: int,
        month: int,
        cycle: int,
    ) -> Savings:
        entry = await self.get_latest_entry(user_id)
        if entry is None:
            entry = Savings(
                user_id=user_id,
                total_saved=amount,
                last_quincenal_savings=0,
                year=year,
                month=month,
                quincenal_cycle=cycle,
            )
            self.session.add(entry)
        else:
            entry.total_saved += amount
            entry.updated_at = datetime.now(UTC).replace(tzinfo=None)
        await self.session.flush()
        await self.session.refresh(entry)
        return entry

    async def get_total_savings(self, user_id: int) -> float:
        latest = await self.get_latest_entry(user_id)
        return float(latest.total_saved if latest is not None else 0)

    async def withdraw_savings(self, user_id: int, amount: float) -> bool:
        latest = await self.get_latest_entry(user_id)
        current = float(latest.total_saved if latest is not None else 0)
        if amount > current or latest is None:
            return False
        latest.total_saved = current - amount
        latest.updated_at = datetime.now(UTC).replace(tzinfo=None)
        await self.session.flush()
        return True

    async def create_goal(self, user_id: int, name: str, target_amount: float) -> SavingsGoal:
        goal = SavingsGoal(user_id=user_id, name=name, target_amount=target_amount)
        self.session.add(goal)
        await self.session.flush()
        await self.session.refresh(goal)
        return goal

    async def list_goals(self, user_id: int) -> list[SavingsGoal]:
        stmt = (
            select(SavingsGoal)
            .where(SavingsGoal.user_id == user_id)
            .order_by(SavingsGoal.created_at.asc(), SavingsGoal.id.asc())
        )
        return list(await self.session.scalars(stmt))

    async def get_goal(self, goal_id: int) -> SavingsGoal | None:
        return await self.session.get(SavingsGoal, goal_id)

    async def update_goal(self, goal_id: int, name: str, target_amount: float) -> SavingsGoal | None:
        goal = await self.get_goal(goal_id)
        if goal is None:
            return None
        goal.name = name
        goal.target_amount = target_amount
        await self.session.flush()
        return goal

    async def delete_goal(self, goal_id: int) -> bool:
        goal = await self.get_goal(goal_id)
        if goal is None:
            return False
        await self.session.delete(goal)
        await self.session.flush()
        return True
