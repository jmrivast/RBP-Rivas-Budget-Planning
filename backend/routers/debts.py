from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status

from backend.middleware import get_finance_use_cases
from backend.schemas.debt import (
    DebtCreate,
    DebtListResponse,
    DebtPaymentCreate,
    DebtPaymentRead,
    DebtRead,
    DebtSummary,
    DebtUpdate,
    PersonalDebtCreate,
    PersonalDebtListResponse,
    PersonalDebtPaymentCreate,
    PersonalDebtPaymentRead,
    PersonalDebtRead,
    PersonalDebtSummary,
    PersonalDebtUpdate,
)
from backend.services.finance_service import FinanceError

router = APIRouter(tags=['debts'])


@router.get('/debts', response_model=DebtListResponse)
async def list_debts(include_inactive: bool = False, uc=Depends(get_finance_use_cases)):
    items = await uc.debts.list(include_inactive=include_inactive)
    reads = [DebtRead.model_validate(item) for item in items]
    return DebtListResponse(
        items=reads,
        summary=DebtSummary(
            count=len(reads),
            total_balance=sum(item.current_balance for item in reads),
            monthly_payment_total=sum(item.monthly_payment for item in reads),
        ),
    )


@router.post('/debts', response_model=DebtRead, status_code=status.HTTP_201_CREATED)
async def create_debt(payload: DebtCreate, uc=Depends(get_finance_use_cases)):
    item = await uc.debts.create(**payload.model_dump())
    return DebtRead.model_validate(item)


@router.put('/debts/{debt_id}', response_model=DebtRead)
async def update_debt(debt_id: int, payload: DebtUpdate, uc=Depends(get_finance_use_cases)):
    try:
        item = await uc.debts.update(debt_id, **payload.model_dump())
    except FinanceError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return DebtRead.model_validate(item)


@router.delete('/debts/{debt_id}', status_code=status.HTTP_204_NO_CONTENT)
async def delete_debt(debt_id: int, uc=Depends(get_finance_use_cases)):
    try:
        await uc.debts.delete(debt_id)
    except FinanceError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.post('/debts/{debt_id}/payment', response_model=DebtPaymentRead, status_code=status.HTTP_201_CREATED)
async def add_debt_payment(debt_id: int, payload: DebtPaymentCreate, uc=Depends(get_finance_use_cases)):
    try:
        item = await uc.debts.add_payment(debt_id, **payload.model_dump())
    except FinanceError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return DebtPaymentRead.model_validate(item)


@router.get('/debts/{debt_id}/payments', response_model=list[DebtPaymentRead])
async def list_debt_payments(debt_id: int, uc=Depends(get_finance_use_cases)):
    try:
        items = await uc.debts.list_payments(debt_id)
    except FinanceError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return [DebtPaymentRead.model_validate(item) for item in items]


@router.get('/personal-debts', response_model=PersonalDebtListResponse)
async def list_personal_debts(include_paid: bool = False, uc=Depends(get_finance_use_cases)):
    items = await uc.personal_debts.list(include_paid=include_paid)
    reads = [PersonalDebtRead.model_validate(item) for item in items]
    return PersonalDebtListResponse(
        items=reads,
        summary=PersonalDebtSummary(count=len(reads), total_balance=sum(item.current_balance for item in reads)),
    )


@router.post('/personal-debts', response_model=PersonalDebtRead, status_code=status.HTTP_201_CREATED)
async def create_personal_debt(payload: PersonalDebtCreate, uc=Depends(get_finance_use_cases)):
    item = await uc.personal_debts.create(
        person=payload.person,
        total_amount=payload.total_amount,
        description=payload.description,
        date_value=payload.date,
    )
    return PersonalDebtRead.model_validate(item)


@router.put('/personal-debts/{debt_id}', response_model=PersonalDebtRead)
async def update_personal_debt(debt_id: int, payload: PersonalDebtUpdate, uc=Depends(get_finance_use_cases)):
    try:
        item = await uc.personal_debts.update(
            debt_id,
            person=payload.person,
            total_amount=payload.total_amount,
            description=payload.description,
            date_value=payload.date,
        )
    except FinanceError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return PersonalDebtRead.model_validate(item)


@router.delete('/personal-debts/{debt_id}', status_code=status.HTTP_204_NO_CONTENT)
async def delete_personal_debt(debt_id: int, uc=Depends(get_finance_use_cases)):
    try:
        await uc.personal_debts.delete(debt_id)
    except FinanceError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.post('/personal-debts/{debt_id}/payment', response_model=PersonalDebtPaymentRead, status_code=status.HTTP_201_CREATED)
async def add_personal_payment(debt_id: int, payload: PersonalDebtPaymentCreate, uc=Depends(get_finance_use_cases)):
    try:
        item = await uc.personal_debts.add_payment(debt_id, **payload.model_dump())
    except FinanceError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return PersonalDebtPaymentRead.model_validate(item)


@router.get('/personal-debts/{debt_id}/payments', response_model=list[PersonalDebtPaymentRead])
async def list_personal_payments(debt_id: int, uc=Depends(get_finance_use_cases)):
    try:
        items = await uc.personal_debts.list_payments(debt_id)
    except FinanceError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return [PersonalDebtPaymentRead.model_validate(item) for item in items]
