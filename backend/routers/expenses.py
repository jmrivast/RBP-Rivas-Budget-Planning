from __future__ import annotations

from datetime import date

from fastapi import APIRouter, Depends, HTTPException, status

from backend.middleware import enforce_freemium_expense_limit, get_finance_use_cases
from backend.schemas.expense import ExpenseCreate, ExpenseRead, ExpenseUpdate
from backend.services.finance_service import FinanceError

router = APIRouter(prefix="/expenses", tags=["expenses"])


def to_read(expense) -> ExpenseRead:
    return ExpenseRead(
        id=expense.id,
        amount=float(expense.amount),
        description=expense.description,
        date=expense.date,
        quincenal_cycle=expense.quincenal_cycle,
        status=expense.status,
        category_ids=expense.category_ids,
    )


@router.get("", response_model=list[ExpenseRead])
async def list_expenses(start: date, end: date, uc=Depends(get_finance_use_cases)):
    return [to_read(item) for item in await uc.expenses.list(start, end)]


@router.post("", response_model=ExpenseRead, status_code=status.HTTP_201_CREATED)
async def create_expense(
    payload: ExpenseCreate,
    _=Depends(enforce_freemium_expense_limit),
    uc=Depends(get_finance_use_cases),
):
    try:
        item = await uc.expenses.create(
            amount=payload.amount,
            description=payload.description,
            category_id=payload.category_id,
            date_value=payload.date,
            source=payload.source,
        )
    except FinanceError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    return to_read(item)


@router.put("/{expense_id}", response_model=ExpenseRead)
async def update_expense(expense_id: int, payload: ExpenseUpdate, uc=Depends(get_finance_use_cases)):
    if payload.amount is None or not payload.description or payload.category_id is None or payload.date is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Para actualizar un gasto se requieren amount, description, category_id y date.",
        )
    try:
        item = await uc.expenses.update(
            expense_id,
            amount=payload.amount,
            description=payload.description,
            category_id=payload.category_id,
            date_value=payload.date,
        )
    except FinanceError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    return to_read(item)


@router.delete("/{expense_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_expense(expense_id: int, uc=Depends(get_finance_use_cases)):
    try:
        await uc.expenses.delete(expense_id)
    except FinanceError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc

