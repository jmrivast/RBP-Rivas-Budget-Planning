from __future__ import annotations

from dataclasses import asdict

from fastapi import APIRouter, Depends

from backend.middleware import get_finance_use_cases
from backend.schemas.dashboard import DashboardRead

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


@router.get("", response_model=DashboardRead)
async def get_dashboard(
    year: int | None = None,
    month: int | None = None,
    cycle: int | None = None,
    uc=Depends(get_finance_use_cases),
):
    data = await uc.dashboard.get(year=year, month=month, cycle=cycle)
    payload = asdict(data)
    payload["quincena_range"] = [data.quincena_range.start, data.quincena_range.end]
    return DashboardRead(**payload)
