from __future__ import annotations

from datetime import date

from fastapi import APIRouter, Body, Depends, HTTPException, Response, status

from backend.middleware import get_finance_use_cases
from backend.schemas.income import IncomeCreate, IncomeRead, IncomeUpdate, SalaryOverrideDelete, SalaryOverrideRequest, SalaryRead, SalaryUpdate
from backend.services.finance_service import FinanceError

router = APIRouter(tags=["income"])


def to_read(item) -> IncomeRead:
    return IncomeRead(
        id=item.id,
        amount=float(item.amount),
        description=item.description,
        date=item.date,
        income_type=item.income_type,
    )


@router.get("/salary", response_model=SalaryRead)
async def get_salary(year: int | None = None, month: int | None = None, cycle: int | None = None, uc=Depends(get_finance_use_cases)):
    base, override, effective = await uc.income.get_salary(year=year, month=month, cycle=cycle)
    return SalaryRead(base=base, override=override, effective=effective)


@router.put("/salary", response_model=SalaryRead)
async def put_salary(payload: SalaryUpdate, uc=Depends(get_finance_use_cases)):
    base = await uc.income.set_salary(payload.amount)
    return SalaryRead(base=base, override=None, effective=base)


@router.put("/salary/override", response_model=SalaryRead)
async def put_salary_override(payload: SalaryOverrideRequest, uc=Depends(get_finance_use_cases)):
    if payload.amount is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="amount es requerido")
    override = await uc.income.set_salary_override(payload.year, payload.month, payload.cycle, payload.amount)
    base, _ov, _eff = await uc.income.get_salary(year=payload.year, month=payload.month, cycle=payload.cycle)
    return SalaryRead(base=base, override=override, effective=override)


@router.delete("/salary/override", status_code=status.HTTP_204_NO_CONTENT)
async def delete_salary_override(payload: SalaryOverrideDelete = Body(...), uc=Depends(get_finance_use_cases)):
    await uc.income.delete_salary_override(payload.year, payload.month, payload.cycle)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/income", response_model=list[IncomeRead])
async def list_income(start: date, end: date, uc=Depends(get_finance_use_cases)):
    return [to_read(item) for item in await uc.income.list(start, end)]


@router.post("/income", response_model=IncomeRead, status_code=status.HTTP_201_CREATED)
async def create_income(payload: IncomeCreate, uc=Depends(get_finance_use_cases)):
    return to_read(await uc.income.create(amount=payload.amount, description=payload.description, date_value=payload.date))


@router.put("/income/{income_id}", response_model=IncomeRead)
async def update_income(income_id: int, payload: IncomeUpdate, uc=Depends(get_finance_use_cases)):
    if payload.amount is None or not payload.description or payload.date is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Para actualizar un ingreso se requieren amount, description y date.",
        )
    try:
        item = await uc.income.update(
            income_id,
            amount=payload.amount,
            description=payload.description,
            date_value=payload.date,
        )
    except FinanceError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    return to_read(item)


@router.delete("/income/{income_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_income(income_id: int, uc=Depends(get_finance_use_cases)):
    try:
        await uc.income.delete(income_id)
    except FinanceError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    return Response(status_code=status.HTTP_204_NO_CONTENT)
