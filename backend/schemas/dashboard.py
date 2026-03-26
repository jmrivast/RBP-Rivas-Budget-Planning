from __future__ import annotations

from datetime import date

from pydantic import BaseModel

from backend.schemas.fixed_payment import FixedPaymentRead


class RecentItemRead(BaseModel):
    date: date
    description: str
    amount: float
    categories: str
    type: str
    fixed_paid: bool = False
    id: int | None = None


class DashboardResponse(BaseModel):
    year: int
    month: int
    cycle: int
    period_mode: str
    salary: float
    extra_income: float
    period_savings: float
    total_savings: float
    dinero_inicial: float
    total_expenses: float
    total_expenses_salary: float
    total_expenses_savings: float
    total_fixed: float
    total_loans: float
    dinero_disponible: float
    avg_daily: float
    expense_count: int
    fixed_count: int
    cat_totals: dict[str, float]
    quincena_range: list[date]
    recent_items: list[RecentItemRead]
    fixed_payments: list[FixedPaymentRead]
    period_title: str


DashboardRead = DashboardResponse
