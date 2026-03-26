from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status

from backend.middleware import get_finance_use_cases
from backend.schemas.fixed_payment import FixedPaymentCreate, FixedPaymentRead, FixedPaymentToggleRequest, FixedPaymentUpdate
from backend.services.finance_service import FinanceError

router = APIRouter(prefix="/fixed-payments", tags=["fixed-payments"])


def to_read(item) -> FixedPaymentRead:
    return FixedPaymentRead(
        id=item.id,
        name=item.name,
        amount=float(item.amount),
        due_day=item.due_day,
        category_id=item.category_id,
        is_paid=getattr(item, "is_paid", False),
        is_overdue=getattr(item, "is_overdue", False),
        due_date=getattr(item, "due_date", ""),
    )


@router.get("", response_model=list[FixedPaymentRead])
async def list_fixed_payments(year: int, month: int, cycle: int, uc=Depends(get_finance_use_cases)):
    return [to_read(item) for item in await uc.fixed_payments.list_for_period(year, month, cycle)]


@router.post("", response_model=FixedPaymentRead, status_code=status.HTTP_201_CREATED)
async def create_fixed_payment(payload: FixedPaymentCreate, uc=Depends(get_finance_use_cases)):
    item = await uc.fixed_payments.create(
        name=payload.name,
        amount=payload.amount,
        due_day=payload.due_day,
        category_id=payload.category_id,
        no_fixed_date=payload.no_fixed_date,
    )
    return to_read(item)


@router.put("/{payment_id}", response_model=FixedPaymentRead)
async def update_fixed_payment(payment_id: int, payload: FixedPaymentUpdate, uc=Depends(get_finance_use_cases)):
    if not payload.name or payload.amount is None or payload.due_day is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Para actualizar un pago fijo se requieren name, amount y due_day.",
        )
    try:
        item = await uc.fixed_payments.update(
            payment_id,
            name=payload.name,
            amount=payload.amount,
            due_day=payload.due_day,
            category_id=payload.category_id,
            no_fixed_date=payload.no_fixed_date,
        )
    except FinanceError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    return to_read(item)


@router.delete("/{payment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_fixed_payment(payment_id: int, uc=Depends(get_finance_use_cases)):
    try:
        await uc.fixed_payments.delete(payment_id)
    except FinanceError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc


@router.post("/{payment_id}/toggle", response_model=FixedPaymentRead)
async def toggle_fixed_payment(payment_id: int, payload: FixedPaymentToggleRequest, uc=Depends(get_finance_use_cases)):
    try:
        item = await uc.fixed_payments.toggle(
            payment_id,
            year=payload.year,
            month=payload.month,
            cycle=payload.cycle,
            paid=payload.paid,
        )
    except FinanceError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    return to_read(item)
