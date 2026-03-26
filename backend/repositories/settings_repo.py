from __future__ import annotations

from datetime import UTC, date, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from backend.database.models import (
    AppSetting,
    CustomQuincena,
    SalaryOverride,
    UserPeriodMode,
    UserSalary,
    UserSetting,
)


class SettingsRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def set_app_setting(self, key: str, value: str) -> AppSetting:
        stmt = select(AppSetting).where(AppSetting.setting_key == key).limit(1)
        setting = await self.session.scalar(stmt)
        if setting is None:
            setting = AppSetting(setting_key=key, setting_value=value)
            self.session.add(setting)
        else:
            setting.setting_value = value
            setting.updated_at = datetime.now(UTC)
        await self.session.flush()
        return setting

    async def get_app_setting(self, key: str, default_value: str = "") -> str:
        stmt = select(AppSetting.setting_value).where(AppSetting.setting_key == key).limit(1)
        value = await self.session.scalar(stmt)
        return str(value) if value is not None else default_value

    async def set_period_mode(self, user_id: int, mode: str) -> UserPeriodMode:
        normalized = "mensual" if mode.strip().lower() == "mensual" else "quincenal"
        stmt = select(UserPeriodMode).where(UserPeriodMode.user_id == user_id).limit(1)
        record = await self.session.scalar(stmt)
        if record is None:
            record = UserPeriodMode(user_id=user_id, mode=normalized)
            self.session.add(record)
        else:
            record.mode = normalized
            record.updated_at = datetime.now(UTC)
        await self.session.flush()
        return record

    async def get_period_mode(self, user_id: int) -> str:
        stmt = select(UserPeriodMode.mode).where(UserPeriodMode.user_id == user_id).limit(1)
        mode = await self.session.scalar(stmt)
        return "mensual" if str(mode).lower() == "mensual" else "quincenal"

    async def set_setting(self, user_id: int, key: str, value: str) -> UserSetting:
        stmt = (
            select(UserSetting)
            .where(UserSetting.user_id == user_id, UserSetting.setting_key == key)
            .limit(1)
        )
        setting = await self.session.scalar(stmt)
        if setting is None:
            setting = UserSetting(user_id=user_id, setting_key=key, setting_value=value)
            self.session.add(setting)
        else:
            setting.setting_value = value
            setting.updated_at = datetime.now(UTC)
        await self.session.flush()
        return setting

    async def get_setting(self, user_id: int, key: str, default_value: str = "") -> str:
        stmt = (
            select(UserSetting.setting_value)
            .where(UserSetting.user_id == user_id, UserSetting.setting_key == key)
            .limit(1)
        )
        value = await self.session.scalar(stmt)
        return str(value) if value is not None else default_value

    async def get_all_settings(self, user_id: int) -> dict[str, str]:
        stmt = select(UserSetting).where(UserSetting.user_id == user_id)
        rows = list(await self.session.scalars(stmt))
        return {row.setting_key: row.setting_value for row in rows}

    async def set_salary(self, user_id: int, amount: float) -> UserSalary:
        stmt = select(UserSalary).where(UserSalary.user_id == user_id).limit(1)
        record = await self.session.scalar(stmt)
        if record is None:
            record = UserSalary(user_id=user_id, amount=amount)
            self.session.add(record)
        else:
            record.amount = amount
            record.updated_at = datetime.now(UTC)
        await self.session.flush()
        return record

    async def get_salary(self, user_id: int) -> float:
        stmt = select(UserSalary.amount).where(UserSalary.user_id == user_id).limit(1)
        amount = await self.session.scalar(stmt)
        return float(amount or 0)

    async def set_salary_override(
        self,
        user_id: int,
        year: int,
        month: int,
        cycle: int,
        amount: float,
    ) -> SalaryOverride:
        stmt = (
            select(SalaryOverride)
            .where(
                SalaryOverride.user_id == user_id,
                SalaryOverride.year == year,
                SalaryOverride.month == month,
                SalaryOverride.cycle == cycle,
            )
            .limit(1)
        )
        record = await self.session.scalar(stmt)
        if record is None:
            record = SalaryOverride(
                user_id=user_id,
                year=year,
                month=month,
                cycle=cycle,
                amount=amount,
            )
            self.session.add(record)
        else:
            record.amount = amount
            record.updated_at = datetime.now(UTC)
        await self.session.flush()
        return record

    async def get_salary_override(
        self, user_id: int, year: int, month: int, cycle: int
    ) -> float | None:
        stmt = select(SalaryOverride.amount).where(
            SalaryOverride.user_id == user_id,
            SalaryOverride.year == year,
            SalaryOverride.month == month,
            SalaryOverride.cycle == cycle,
        )
        amount = await self.session.scalar(stmt)
        return float(amount) if amount is not None else None

    async def delete_salary_override(self, user_id: int, year: int, month: int, cycle: int) -> bool:
        stmt = (
            select(SalaryOverride)
            .where(
                SalaryOverride.user_id == user_id,
                SalaryOverride.year == year,
                SalaryOverride.month == month,
                SalaryOverride.cycle == cycle,
            )
            .limit(1)
        )
        record = await self.session.scalar(stmt)
        if record is None:
            return False
        await self.session.delete(record)
        await self.session.flush()
        return True

    async def set_custom_quincena(
        self,
        user_id: int,
        year: int,
        month: int,
        cycle: int,
        start_date: date,
        end_date: date,
    ) -> CustomQuincena:
        stmt = (
            select(CustomQuincena)
            .where(
                CustomQuincena.user_id == user_id,
                CustomQuincena.year == year,
                CustomQuincena.month == month,
                CustomQuincena.cycle == cycle,
            )
            .limit(1)
        )
        record = await self.session.scalar(stmt)
        if record is None:
            record = CustomQuincena(
                user_id=user_id,
                year=year,
                month=month,
                cycle=cycle,
                start_date=start_date,
                end_date=end_date,
            )
            self.session.add(record)
        else:
            record.start_date = start_date
            record.end_date = end_date
        await self.session.flush()
        return record

    async def get_custom_quincena(
        self, user_id: int, year: int, month: int, cycle: int
    ) -> CustomQuincena | None:
        stmt = (
            select(CustomQuincena)
            .where(
                CustomQuincena.user_id == user_id,
                CustomQuincena.year == year,
                CustomQuincena.month == month,
                CustomQuincena.cycle == cycle,
            )
            .limit(1)
        )
        return await self.session.scalar(stmt)

    async def get_custom_quincena_range(
        self, user_id: int, year: int, month: int, cycle: int
    ) -> tuple[date, date] | None:
        record = await self.get_custom_quincena(user_id, year, month, cycle)
        if record is None:
            return None
        return record.start_date, record.end_date

    async def delete_custom_quincena(self, user_id: int, year: int, month: int, cycle: int) -> bool:
        record = await self.get_custom_quincena(user_id, year, month, cycle)
        if record is None:
            return False
        await self.session.delete(record)
        await self.session.flush()
        return True
