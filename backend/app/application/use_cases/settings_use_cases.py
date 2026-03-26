from __future__ import annotations

from dataclasses import dataclass
from datetime import date

from backend.app.domain.ports import FinancePort


@dataclass(slots=True)
class SettingsUseCases:
    finance: FinancePort

    async def get(self) -> dict[str, object]:
        return await self.finance.get_settings_payload()

    async def update(
        self,
        *,
        period_mode: str | None = None,
        pay_day_1: int | None = None,
        pay_day_2: int | None = None,
        monthly_pay_day: int | None = None,
        theme: str | None = None,
        auto_export: bool | None = None,
        include_beta: bool | None = None,
    ) -> dict[str, object]:
        return await self.finance.update_settings(
            period_mode=period_mode,
            pay_day_1=pay_day_1,
            pay_day_2=pay_day_2,
            monthly_pay_day=monthly_pay_day,
            theme=theme,
            auto_export=auto_export,
            include_beta=include_beta,
        )

    async def get_custom_quincena(self, year: int, month: int, cycle: int) -> tuple[str, str]:
        return await self.finance.get_custom_quincena(year, month, cycle)

    async def get_period_range(self, year: int, month: int, cycle: int) -> tuple[str, str]:
        return await self.finance.get_period_range(year, month, cycle)

    async def get_cycle_for_date(self, value: date) -> int:
        return await self.finance.get_cycle_for_date(value)

    async def put_custom_quincena(
        self,
        year: int,
        month: int,
        cycle: int,
        start_date: date,
        end_date: date,
    ) -> tuple[str, str]:
        return await self.finance.set_custom_quincena(
            year,
            month,
            cycle,
            start_date,
            end_date,
        )

    async def delete_custom_quincena(self, year: int, month: int, cycle: int) -> None:
        await self.finance.delete_custom_quincena(year, month, cycle)
