from __future__ import annotations

from backend.app.domain.entities import (
    AuthToken,
    Category,
    DashboardData,
    Debt,
    DebtPayment,
    Expense,
    FixedPayment,
    FixedPaymentStatus,
    Income,
    Loan,
    PersonalDebt,
    PersonalDebtPayment,
    SavingsGoal,
    User,
)
from backend.app.domain.value_objects import PeriodRange


def to_user(model) -> User:
    return User(
        id=model.id,
        username=model.username,
        email=getattr(model, 'email', None),
        pin_length=getattr(model, 'pin_length', 0),
        is_active=getattr(model, 'is_active', True),
        password_hash=getattr(model, 'password_hash', None),
        pin_hash=getattr(model, 'pin_hash', None),
    )


def to_auth_token(result) -> AuthToken:
    return AuthToken(
        access_token=result.access_token,
        token_type=getattr(result, 'token_type', 'bearer'),
        expires_at=result.expires_at,
        refresh_token=getattr(result, 'refresh_token', None),
        refresh_expires_at=getattr(result, 'refresh_expires_at', None),
        user=to_user(result.user),
    )


def to_category(model) -> Category:
    return Category(
        id=model.id,
        user_id=model.user_id,
        name=model.name,
        color=getattr(model, 'color', None),
        icon=getattr(model, 'icon', None),
    )


def to_expense(model) -> Expense:
    category_ids = [link.category_id for link in getattr(model, 'expense_categories', [])]
    if not category_ids:
        category_ids = [category.id for category in getattr(model, 'categories', [])]
    return Expense(
        id=model.id,
        user_id=model.user_id,
        amount=float(model.amount),
        description=model.description,
        date=model.date,
        quincenal_cycle=model.quincenal_cycle,
        status=model.status,
        category_ids=category_ids,
    )


def to_fixed_payment(model) -> FixedPayment:
    return FixedPayment(
        id=model.id,
        user_id=model.user_id,
        name=model.name,
        amount=float(model.amount),
        due_day=model.due_day,
        category_id=model.category_id,
        is_active=getattr(model, 'is_active', True),
    )


def to_fixed_payment_status(model) -> FixedPaymentStatus:
    return FixedPaymentStatus(
        id=model.id,
        name=model.name,
        amount=float(model.amount),
        due_day=model.due_day,
        category_id=model.category_id,
        is_paid=model.is_paid,
        is_overdue=model.is_overdue,
        due_date=model.due_date,
    )


def to_income(model) -> Income:
    return Income(
        id=model.id,
        user_id=model.user_id,
        amount=float(model.amount),
        description=model.description,
        date=model.date,
        income_type=model.income_type,
    )


def to_loan(model) -> Loan:
    return Loan(
        id=model.id,
        user_id=model.user_id,
        person=model.person,
        amount=float(model.amount),
        description=getattr(model, 'description', None),
        date=model.date,
        is_paid=bool(model.is_paid),
        paid_date=getattr(model, 'paid_date', None),
        deduction_type=getattr(model, 'deduction_type', 'ninguno'),
    )


def to_debt(model) -> Debt:
    return Debt(
        id=model.id,
        user_id=model.user_id,
        name=model.name,
        principal_amount=float(model.principal_amount),
        annual_rate=float(model.annual_rate),
        term_months=model.term_months,
        start_date=model.start_date,
        payment_day=model.payment_day,
        monthly_payment=float(model.monthly_payment),
        current_balance=float(model.current_balance),
        is_active=bool(model.is_active),
    )


def to_debt_payment(model) -> DebtPayment:
    return DebtPayment(
        id=model.id,
        debt_id=model.debt_id,
        payment_date=model.payment_date,
        total_amount=float(model.total_amount),
        interest_amount=float(model.interest_amount),
        capital_amount=float(model.capital_amount),
        notes=getattr(model, 'notes', None),
    )


def to_personal_debt(model) -> PersonalDebt:
    return PersonalDebt(
        id=model.id,
        user_id=model.user_id,
        person=model.person,
        total_amount=float(model.total_amount),
        description=getattr(model, 'description', None),
        date=model.date,
        total_paid=float(getattr(model, 'total_paid', 0) or 0),
        remaining_amount=float(getattr(model, 'current_balance', 0) or 0),
        is_paid=bool(model.is_paid),
    )


def to_personal_debt_payment(model) -> PersonalDebtPayment:
    return PersonalDebtPayment(
        id=model.id,
        debt_id=model.personal_debt_id,
        payment_date=model.payment_date,
        amount=float(model.amount),
        notes=getattr(model, 'notes', None),
    )


def to_savings_goal(model) -> SavingsGoal:
    return SavingsGoal(
        id=model.id,
        user_id=model.user_id,
        name=model.name,
        target_amount=float(model.target_amount),
        current_amount=float(getattr(model, 'current_amount', 0) or 0),
    )


def to_dashboard(result) -> DashboardData:
    return DashboardData(
        initial_money=float(result.initial_money),
        total_spent=float(result.total_spent),
        available_money=float(result.available_money),
        average_daily=float(result.average_daily),
        pending_loans=float(result.pending_loans),
        total_savings=float(result.total_savings),
        raw_expenses=[to_expense(item) for item in result.raw_expenses],
        pie_categories=list(result.pie_categories),
        pie_values=[float(value) for value in result.pie_values],
        fixed_payments_total=float(getattr(result, 'fixed_payments_total', 0) or 0),
        monthly_fixed_payments_total=float(getattr(result, 'monthly_fixed_payments_total', 0) or 0),
        period_range=PeriodRange(
            start=result.period_range.start,
            end=result.period_range.end,
        ) if getattr(result, 'period_range', None) else None,
    )
