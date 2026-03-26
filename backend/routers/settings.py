from __future__ import annotations

from fastapi import APIRouter, Depends

from backend.middleware import get_finance_use_cases
from backend.schemas.settings import CustomQuincenaRead, CustomQuincenaUpdate, SettingsRead, SettingsUpdate

router = APIRouter(prefix="/settings", tags=["settings"])


@router.get("", response_model=SettingsRead)
async def get_settings(uc=Depends(get_finance_use_cases)):
    return SettingsRead.model_validate(await uc.settings.get())


@router.put("", response_model=SettingsRead)
async def update_settings(payload: SettingsUpdate, uc=Depends(get_finance_use_cases)):
    return SettingsRead.model_validate(
        await uc.settings.update(
            period_mode=payload.period_mode,
            pay_day_1=payload.pay_day_1,
            pay_day_2=payload.pay_day_2,
            monthly_pay_day=payload.monthly_pay_day,
            theme=payload.theme,
            auto_export=payload.auto_export,
            include_beta=payload.include_beta,
        )
    )


@router.get("/quincena", response_model=CustomQuincenaRead)
async def get_custom_quincena(year: int, month: int, cycle: int, uc=Depends(get_finance_use_cases)):
    start_date, end_date = await uc.settings.get_custom_quincena(year, month, cycle)
    return CustomQuincenaRead(year=year, month=month, cycle=cycle, start_date=start_date, end_date=end_date)


@router.put("/quincena", response_model=CustomQuincenaRead)
async def set_custom_quincena(payload: CustomQuincenaUpdate, uc=Depends(get_finance_use_cases)):
    start_date, end_date = await uc.settings.put_custom_quincena(
        payload.year,
        payload.month,
        payload.cycle,
        payload.start_date,
        payload.end_date,
    )
    return CustomQuincenaRead(year=payload.year, month=payload.month, cycle=payload.cycle, start_date=start_date, end_date=end_date)


@router.delete("/quincena")
async def delete_custom_quincena(year: int, month: int, cycle: int, uc=Depends(get_finance_use_cases)):
    await uc.settings.delete_custom_quincena(year, month, cycle)
    return {"ok": True}
