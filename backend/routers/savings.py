from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status

from backend.middleware import get_finance_use_cases
from backend.schemas.savings import SavingsActionRequest, SavingsGoalCreate, SavingsGoalRead, SavingsGoalUpdate, SavingsSummary, WithdrawResponse
from backend.services.finance_service import FinanceError

router = APIRouter(prefix="/savings", tags=["savings"])


@router.get("", response_model=SavingsSummary)
async def get_savings(year: int, month: int, cycle: int, uc=Depends(get_finance_use_cases)):
    total, period = await uc.savings.get_summary(year, month, cycle)
    return SavingsSummary(total=total, period_savings=period)


@router.post("/deposit", response_model=SavingsSummary)
async def deposit(payload: SavingsActionRequest, uc=Depends(get_finance_use_cases)):
    total = await uc.savings.deposit(payload.amount)
    return SavingsSummary(total=total, period_savings=0.0)


@router.post("/extra", response_model=SavingsSummary)
async def extra(payload: SavingsActionRequest, uc=Depends(get_finance_use_cases)):
    total = await uc.savings.extra(payload.amount)
    return SavingsSummary(total=total, period_savings=0.0)


@router.post("/withdraw", response_model=WithdrawResponse)
async def withdraw(payload: SavingsActionRequest, uc=Depends(get_finance_use_cases)):
    ok = await uc.savings.withdraw(payload.amount)
    total = await uc.savings.get_total()
    return WithdrawResponse(ok=ok, total=total)


@router.get("/goals", response_model=list[SavingsGoalRead])
async def list_goals(uc=Depends(get_finance_use_cases)):
    return [SavingsGoalRead.model_validate(goal) for goal in await uc.savings.list_goals()]


@router.post("/goals", response_model=SavingsGoalRead, status_code=status.HTTP_201_CREATED)
async def create_goal(payload: SavingsGoalCreate, uc=Depends(get_finance_use_cases)):
    return SavingsGoalRead.model_validate(await uc.savings.create_goal(payload.name, payload.target_amount))


@router.put("/goals/{goal_id}", response_model=SavingsGoalRead)
async def update_goal(goal_id: int, payload: SavingsGoalUpdate, uc=Depends(get_finance_use_cases)):
    if not payload.name or payload.target_amount is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Para actualizar una meta se requieren name y target_amount.",
        )
    try:
        goal = await uc.savings.update_goal(goal_id, payload.name, payload.target_amount)
    except FinanceError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    return SavingsGoalRead.model_validate(goal)


@router.delete("/goals/{goal_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_goal(goal_id: int, uc=Depends(get_finance_use_cases)):
    try:
        await uc.savings.delete_goal(goal_id)
    except FinanceError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    return None
