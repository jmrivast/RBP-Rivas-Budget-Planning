from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date, datetime

from backend.app.domain.value_objects import PeriodRange


@dataclass(slots=True)
class User:
    id: int
    username: str
    email: str | None = None
    pin_length: int = 0
    is_active: bool = True
    password_hash: str | None = None
    pin_hash: str | None = None


@dataclass(slots=True)
class AuthToken:
    access_token: str
    token_type: str
    expires_at: datetime
    user: User
    refresh_token: str | None = None
    refresh_expires_at: datetime | None = None


@dataclass(slots=True)
class Category:
    id: int
    user_id: int
    name: str
    color: str | None = None
    icon: str | None = None


@dataclass(slots=True)
class Expense:
    id: int
    user_id: int
    amount: float
    description: str
    date: date
    quincenal_cycle: int
    status: str
    category_ids: list[int] = field(default_factory=list)


@dataclass(slots=True)
class FixedPayment:
    id: int
    user_id: int
    name: str
    amount: float
    due_day: int
    category_id: int | None = None
    is_active: bool = True


@dataclass(slots=True)
class FixedPaymentStatus:
    id: int
    name: str
    amount: float
    due_day: int
    category_id: int | None
    is_paid: bool
    is_overdue: bool
    due_date: str


@dataclass(slots=True)
class Income:
    id: int
    user_id: int
    amount: float
    description: str
    date: date
    income_type: str = 'bonus'


@dataclass(slots=True)
class Loan:
    id: int
    user_id: int
    person: str
    amount: float
    description: str | None
    date: date
    is_paid: bool
    paid_date: date | None = None
    deduction_type: str = 'ninguno'


@dataclass(slots=True)
class DebtPayment:
    id: int
    debt_id: int
    payment_date: date
    total_amount: float
    interest_amount: float
    capital_amount: float
    notes: str | None = None


@dataclass(slots=True)
class Debt:
    id: int
    user_id: int
    name: str
    principal_amount: float
    annual_rate: float
    term_months: int
    start_date: date
    payment_day: int
    monthly_payment: float
    current_balance: float
    is_active: bool


@dataclass(slots=True)
class PersonalDebt:
    id: int
    user_id: int
    person: str
    total_amount: float
    description: str | None
    date: date
    total_paid: float
    remaining_amount: float
    is_paid: bool


@dataclass(slots=True)
class PersonalDebtPayment:
    id: int
    debt_id: int
    payment_date: date
    amount: float
    notes: str | None = None


@dataclass(slots=True)
class SavingsGoal:
    id: int
    user_id: int
    name: str
    target_amount: float
    current_amount: float = 0.0


@dataclass(slots=True)
class SavingsSnapshot:
    total_saved: float
    period_saved: float = 0.0


@dataclass(slots=True)
class Settings:
    period_mode: str
    quincenal_pay_day_1: int = 1
    quincenal_pay_day_2: int = 16
    monthly_pay_day: int = 1


@dataclass(slots=True)
class CustomQuincena:
    year: int
    month: int
    cycle: int
    start_date: str
    end_date: str


@dataclass(slots=True)
class DashboardData:
    initial_money: float
    total_spent: float
    available_money: float
    average_daily: float
    pending_loans: float
    total_savings: float
    raw_expenses: list[Expense]
    pie_categories: list[str]
    pie_values: list[float]
    fixed_payments_total: float = 0.0
    monthly_fixed_payments_total: float = 0.0
    period_range: PeriodRange | None = None
