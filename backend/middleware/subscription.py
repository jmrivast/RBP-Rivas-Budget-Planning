from __future__ import annotations

from datetime import date

from fastapi import Depends, HTTPException, status

from backend.middleware.auth import get_current_user, get_finance_use_cases, get_subscription_use_cases


async def enforce_expense_limit(
    current_user=Depends(get_current_user),
    finance_uc=Depends(get_finance_use_cases),
    subscriptions=Depends(get_subscription_use_cases),
) -> None:
    today = date.today()
    cycle = await finance_uc.settings.get_cycle_for_date(today)
    start_iso, end_iso = await finance_uc.settings.get_period_range(today.year, today.month, cycle)
    items = await finance_uc.expenses.list(date.fromisoformat(start_iso), date.fromisoformat(end_iso))
    allowed = await subscriptions.can_create_expense(current_user.id, len(items))
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail='Plan free excedio el limite de gastos para este periodo.',
        )


async def enforce_freemium_expense_limit(
    current_user=Depends(get_current_user),
    finance_uc=Depends(get_finance_use_cases),
    subscriptions=Depends(get_subscription_use_cases),
) -> None:
    return await enforce_expense_limit(current_user=current_user, finance_uc=finance_uc, subscriptions=subscriptions)
