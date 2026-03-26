from __future__ import annotations

from dataclasses import dataclass

from backend.app.domain.entities import SavingsGoal
from backend.app.domain.ports import FinancePort


@dataclass(slots=True)
class SavingsUseCases:
    finance: FinancePort

    async def get_total(self) -> float:
        return await self.finance.get_total_savings()

    async def get_summary(self, year: int, month: int, cycle: int) -> tuple[float, float]:
        total = await self.finance.get_total_savings()
        period = await self.finance.get_period_savings(year, month, cycle)
        return total, period

    async def deposit(self, amount: float) -> float:
        return await self.finance.add_savings(amount)

    async def extra(self, amount: float) -> float:
        return await self.finance.add_extra_savings(amount)

    async def withdraw(self, amount: float) -> bool:
        return await self.finance.withdraw_savings(amount)

    async def list_goals(self) -> list[SavingsGoal]:
        return await self.finance.list_savings_goals()

    async def create_goal(self, name: str, target_amount: float) -> SavingsGoal:
        return await self.finance.create_savings_goal(name, target_amount)

    async def update_goal(self, goal_id: int, name: str, target_amount: float) -> SavingsGoal:
        return await self.finance.update_savings_goal(goal_id, name=name, target_amount=target_amount)

    async def delete_goal(self, goal_id: int) -> None:
        await self.finance.delete_savings_goal(goal_id)
