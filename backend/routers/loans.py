from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status

from backend.middleware import get_finance_use_cases
from backend.schemas.loan import LoanCreate, LoanPayResponse, LoanRead, LoanUpdate
from backend.services.finance_service import FinanceError

router = APIRouter(prefix='/loans', tags=['loans'])


@router.get('', response_model=list[LoanRead])
async def list_loans(include_paid: bool = False, uc=Depends(get_finance_use_cases)):
    return [LoanRead.model_validate(item) for item in await uc.loans.list(include_paid=include_paid)]


@router.post('', response_model=LoanRead, status_code=status.HTTP_201_CREATED)
async def create_loan(payload: LoanCreate, uc=Depends(get_finance_use_cases)):
    try:
        item = await uc.loans.create(
            person=payload.person,
            amount=payload.amount,
            description=payload.description,
            date_value=payload.date,
            deduction_type=payload.deduction_type,
        )
    except FinanceError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    return LoanRead.model_validate(item)


@router.put('/{loan_id}', response_model=LoanRead)
async def update_loan(loan_id: int, payload: LoanUpdate, uc=Depends(get_finance_use_cases)):
    if payload.person is None or payload.amount is None or payload.date is None or payload.deduction_type is None:
        raise HTTPException(status_code=400, detail='person, amount, date y deduction_type son requeridos.')
    try:
        item = await uc.loans.update(
            loan_id,
            person=payload.person,
            amount=payload.amount,
            description=payload.description,
            date_value=payload.date,
            deduction_type=payload.deduction_type,
        )
    except FinanceError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return LoanRead.model_validate(item)


@router.post('/{loan_id}/pay', response_model=LoanPayResponse)
async def pay_loan(loan_id: int, uc=Depends(get_finance_use_cases)):
    try:
        item = await uc.loans.pay(loan_id)
    except FinanceError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return LoanPayResponse(loan=LoanRead.model_validate(item))


@router.delete('/{loan_id}', status_code=status.HTTP_204_NO_CONTENT)
async def delete_loan(loan_id: int, uc=Depends(get_finance_use_cases)):
    try:
        await uc.loans.delete(loan_id)
    except FinanceError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
