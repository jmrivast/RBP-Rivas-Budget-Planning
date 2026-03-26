from __future__ import annotations

from dataclasses import dataclass

from backend.app.domain.entities import DashboardData
from backend.app.domain.ports import FinancePort


@dataclass(slots=True)
class DashboardUseCase:
    finance: FinancePort

    async def get(
        self,
        *,
        year: int | None = None,
        month: int | None = None,
        cycle: int | None = None,
    ) -> DashboardData:
        return await self.finance.get_dashboard_data(year=year, month=month, cycle=cycle)
