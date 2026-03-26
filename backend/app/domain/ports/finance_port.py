from __future__ import annotations

from datetime import date
from typing import Protocol

from backend.app.domain.entities import (
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
)


class FinancePort(Protocol):
    async def get_dashboard_data(
        self,
        *,
        year: int | None = None,
        month: int | None = None,
        cycle: int | None = None,
    ) -> DashboardData: ...

    async def get_categories(self) -> list[Category]: ...
    async def add_category(self, name: str) -> Category: ...
    async def rename_category(self, category_id: int, new_name: str) -> Category: ...
    async def delete_category(self, category_id: int) -> None: ...

    async def list_expenses(self, start_date: date, end_date: date) -> list[Expense]: ...
    async def add_expense(
        self,
        *,
        amount: float,
        description: str,
        category_id: int,
        date_value: date,
        source: str = 'sueldo',
    ) -> Expense: ...
    async def update_expense(
        self,
        expense_id: int,
        *,
        amount: float,
        description: str,
        category_id: int,
        date_value: date,
    ) -> Expense: ...
    async def delete_expense(self, expense_id: int) -> None: ...

    async def get_fixed_payments_for_period(
        self,
        year: int,
        month: int,
        cycle: int,
    ) -> list[FixedPaymentStatus]: ...
    async def add_fixed_payment(
        self,
        *,
        name: str,
        amount: float,
        due_day: int,
        category_id: int | None,
        no_fixed_date: bool = False,
    ) -> FixedPayment: ...
    async def update_fixed_payment(
        self,
        payment_id: int,
        *,
        name: str,
        amount: float,
        due_day: int,
        category_id: int | None,
        no_fixed_date: bool = False,
    ) -> FixedPayment: ...
    async def set_fixed_payment_paid(
        self,
        payment_id: int,
        year: int,
        month: int,
        cycle: int,
        paid: bool,
    ) -> FixedPaymentStatus: ...
    async def delete_fixed_payment(self, payment_id: int) -> None: ...

    async def list_income(self, start_date: date, end_date: date) -> list[Income]: ...
    async def add_income(self, *, amount: float, description: str, date_value: date) -> Income: ...
    async def update_income(
        self,
        income_id: int,
        *,
        amount: float,
        description: str,
        date_value: date,
    ) -> Income: ...
    async def delete_income(self, income_id: int) -> None: ...

    async def list_loans(self, *, include_paid: bool = False) -> list[Loan]: ...
    async def add_loan(
        self,
        *,
        person: str,
        amount: float,
        description: str | None,
        date_value: date,
        deduction_type: str = 'ninguno',
    ) -> Loan: ...
    async def update_loan(
        self,
        loan_id: int,
        *,
        person: str,
        amount: float,
        description: str | None,
        date_value: date,
        deduction_type: str,
    ) -> Loan: ...
    async def pay_loan(self, loan_id: int) -> Loan: ...
    async def delete_loan(self, loan_id: int) -> None: ...

    async def list_debts(self, *, include_inactive: bool = False) -> list[Debt]: ...
    async def create_debt(
        self,
        *,
        name: str,
        principal_amount: float,
        annual_rate: float,
        term_months: int,
        start_date: date,
        payment_day: int,
    ) -> Debt: ...
    async def update_debt(
        self,
        debt_id: int,
        *,
        name: str,
        principal_amount: float,
        annual_rate: float,
        term_months: int,
        start_date: date,
        payment_day: int,
    ) -> Debt: ...
    async def delete_debt(self, debt_id: int) -> None: ...
    async def add_debt_payment(
        self,
        debt_id: int,
        *,
        payment_date: date,
        total_amount: float,
        interest_amount: float,
        capital_amount: float,
        notes: str | None,
    ) -> DebtPayment: ...
    async def list_debt_payments(self, debt_id: int) -> list[DebtPayment]: ...

    async def list_personal_debts(self, *, include_paid: bool = False) -> list[PersonalDebt]: ...
    async def create_personal_debt(
        self,
        *,
        person: str,
        total_amount: float,
        description: str | None,
        date_value: date,
    ) -> PersonalDebt: ...
    async def update_personal_debt(
        self,
        debt_id: int,
        *,
        person: str,
        total_amount: float,
        description: str | None,
        date_value: date,
    ) -> PersonalDebt: ...
    async def delete_personal_debt(self, debt_id: int) -> None: ...
    async def add_personal_debt_payment(
        self,
        debt_id: int,
        *,
        payment_date: date,
        amount: float,
        notes: str | None,
    ) -> PersonalDebtPayment: ...
    async def list_personal_debt_payments(self, debt_id: int) -> list[PersonalDebtPayment]: ...

    async def get_salary(self) -> float: ...
    async def set_salary(self, amount: float) -> float: ...
    async def get_salary_override(self, year: int, month: int, cycle: int) -> float | None: ...
    async def set_salary_override(self, year: int, month: int, cycle: int, amount: float) -> float: ...
    async def delete_salary_override(self, year: int, month: int, cycle: int) -> None: ...

    async def get_total_savings(self) -> float: ...
    async def get_period_savings(self, year: int, month: int, cycle: int) -> float: ...
    async def add_savings(self, amount: float) -> float: ...
    async def add_extra_savings(self, amount: float) -> float: ...
    async def withdraw_savings(self, amount: float) -> bool: ...

    async def list_savings_goals(self) -> list[SavingsGoal]: ...
    async def create_savings_goal(self, name: str, target_amount: float) -> SavingsGoal: ...
    async def update_savings_goal(self, goal_id: int, name: str, target_amount: float) -> SavingsGoal: ...
    async def delete_savings_goal(self, goal_id: int) -> None: ...

    async def get_settings_payload(self) -> dict[str, object]: ...
    async def update_settings(
        self,
        *,
        period_mode: str | None = None,
        pay_day_1: int | None = None,
        pay_day_2: int | None = None,
        monthly_pay_day: int | None = None,
        theme: str | None = None,
        auto_export: bool | None = None,
        include_beta: bool | None = None,
    ) -> dict[str, object]: ...

    async def get_custom_quincena(self, year: int, month: int, cycle: int) -> tuple[str, str]: ...
    async def get_period_range(self, year: int, month: int, cycle: int) -> tuple[str, str]: ...
    async def get_cycle_for_date(self, value: date) -> int: ...
    async def set_custom_quincena(
        self,
        year: int,
        month: int,
        cycle: int,
        start_date: date,
        end_date: date,
    ) -> tuple[str, str]: ...
    async def delete_custom_quincena(self, year: int, month: int, cycle: int) -> None: ...
