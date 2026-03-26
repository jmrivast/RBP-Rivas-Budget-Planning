from __future__ import annotations

from datetime import date

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
from backend.app.domain.ports import FinancePort
from backend.app.infrastructure.adapters.mappers import (
    to_category,
    to_dashboard,
    to_debt,
    to_debt_payment,
    to_expense,
    to_fixed_payment,
    to_fixed_payment_status,
    to_income,
    to_loan,
    to_personal_debt,
    to_personal_debt_payment,
    to_savings_goal,
)
from backend.services.finance_service import FinanceService


class FinanceServiceAdapter(FinancePort):
    """Adapter that exposes FinanceService through the domain finance port."""

    def __init__(self, service: FinanceService) -> None:
        self._service = service

    async def get_dashboard_data(self, *, year: int | None = None, month: int | None = None, cycle: int | None = None) -> DashboardData:
        result = await self._service.get_dashboard_data(year=year, month=month, cycle=cycle)
        return to_dashboard(result)

    async def get_categories(self) -> list[Category]:
        return [to_category(item) for item in await self._service.get_categories()]

    async def add_category(self, name: str) -> Category:
        return to_category(await self._service.add_category(name))

    async def rename_category(self, category_id: int, new_name: str) -> Category:
        return to_category(await self._service.rename_category(category_id, new_name))

    async def delete_category(self, category_id: int) -> None:
        await self._service.delete_category(category_id)

    async def list_expenses(self, start_date: date, end_date: date) -> list[Expense]:
        return [to_expense(item) for item in await self._service.list_expenses(start_date, end_date)]

    async def add_expense(self, *, amount: float, description: str, category_id: int, date_value: date, source: str = 'sueldo') -> Expense:
        return to_expense(
            await self._service.add_expense(
                amount=amount,
                description=description,
                category_id=category_id,
                date_value=date_value,
                source=source,
            )
        )

    async def update_expense(self, expense_id: int, *, amount: float, description: str, category_id: int, date_value: date) -> Expense:
        return to_expense(
            await self._service.update_expense(
                expense_id,
                amount=amount,
                description=description,
                category_id=category_id,
                date_value=date_value,
            )
        )

    async def delete_expense(self, expense_id: int) -> None:
        await self._service.delete_expense(expense_id)

    async def get_fixed_payments_for_period(self, year: int, month: int, cycle: int) -> list[FixedPaymentStatus]:
        return [to_fixed_payment_status(item) for item in await self._service.get_fixed_payments_for_period(year, month, cycle)]

    async def add_fixed_payment(self, *, name: str, amount: float, due_day: int, category_id: int | None, no_fixed_date: bool = False) -> FixedPayment:
        return to_fixed_payment(
            await self._service.add_fixed_payment(
                name=name,
                amount=amount,
                due_day=due_day,
                category_id=category_id,
                no_fixed_date=no_fixed_date,
            )
        )

    async def update_fixed_payment(self, payment_id: int, *, name: str, amount: float, due_day: int, category_id: int | None, no_fixed_date: bool = False) -> FixedPayment:
        return to_fixed_payment(
            await self._service.update_fixed_payment(
                payment_id,
                name=name,
                amount=amount,
                due_day=due_day,
                category_id=category_id,
                no_fixed_date=no_fixed_date,
            )
        )

    async def set_fixed_payment_paid(self, payment_id: int, year: int, month: int, cycle: int, paid: bool) -> FixedPaymentStatus:
        return to_fixed_payment_status(await self._service.set_fixed_payment_paid(payment_id, year, month, cycle, paid))

    async def delete_fixed_payment(self, payment_id: int) -> None:
        await self._service.delete_fixed_payment(payment_id)

    async def list_income(self, start_date: date, end_date: date) -> list[Income]:
        return [to_income(item) for item in await self._service.list_income(start_date, end_date)]

    async def add_income(self, *, amount: float, description: str, date_value: date) -> Income:
        return to_income(await self._service.add_income(amount=amount, description=description, date_value=date_value))

    async def update_income(self, income_id: int, *, amount: float, description: str, date_value: date) -> Income:
        return to_income(await self._service.update_income(income_id, amount=amount, description=description, date_value=date_value))

    async def delete_income(self, income_id: int) -> None:
        await self._service.delete_income(income_id)

    async def list_loans(self, *, include_paid: bool = False) -> list[Loan]:
        return [to_loan(item) for item in await self._service.list_loans(include_paid=include_paid)]

    async def add_loan(self, *, person: str, amount: float, description: str | None, date_value: date, deduction_type: str = 'ninguno') -> Loan:
        return to_loan(
            await self._service.add_loan(
                person=person,
                amount=amount,
                description=description,
                date_value=date_value,
                deduction_type=deduction_type,
            )
        )

    async def update_loan(self, loan_id: int, *, person: str, amount: float, description: str | None, date_value: date, deduction_type: str) -> Loan:
        return to_loan(
            await self._service.update_loan(
                loan_id,
                person=person,
                amount=amount,
                description=description,
                date_value=date_value,
                deduction_type=deduction_type,
            )
        )

    async def pay_loan(self, loan_id: int) -> Loan:
        return to_loan(await self._service.pay_loan(loan_id))

    async def delete_loan(self, loan_id: int) -> None:
        await self._service.delete_loan(loan_id)

    async def list_debts(self, *, include_inactive: bool = False) -> list[Debt]:
        return [to_debt(item) for item in await self._service.list_debts(include_inactive=include_inactive)]

    async def create_debt(self, *, name: str, principal_amount: float, annual_rate: float, term_months: int, start_date: date, payment_day: int) -> Debt:
        return to_debt(
            await self._service.create_debt(
                name=name,
                principal_amount=principal_amount,
                annual_rate=annual_rate,
                term_months=term_months,
                start_date=start_date,
                payment_day=payment_day,
            )
        )

    async def update_debt(self, debt_id: int, *, name: str, principal_amount: float, annual_rate: float, term_months: int, start_date: date, payment_day: int) -> Debt:
        return to_debt(
            await self._service.update_debt(
                debt_id,
                name=name,
                principal_amount=principal_amount,
                annual_rate=annual_rate,
                term_months=term_months,
                start_date=start_date,
                payment_day=payment_day,
            )
        )

    async def delete_debt(self, debt_id: int) -> None:
        await self._service.delete_debt(debt_id)

    async def add_debt_payment(self, debt_id: int, *, payment_date: date, total_amount: float, interest_amount: float, capital_amount: float, notes: str | None) -> DebtPayment:
        return to_debt_payment(
            await self._service.add_debt_payment(
                debt_id,
                payment_date=payment_date,
                total_amount=total_amount,
                interest_amount=interest_amount,
                capital_amount=capital_amount,
                notes=notes,
            )
        )

    async def list_debt_payments(self, debt_id: int) -> list[DebtPayment]:
        return [to_debt_payment(item) for item in await self._service.list_debt_payments(debt_id)]

    async def list_personal_debts(self, *, include_paid: bool = False) -> list[PersonalDebt]:
        return [to_personal_debt(item) for item in await self._service.list_personal_debts(include_paid=include_paid)]

    async def create_personal_debt(self, *, person: str, total_amount: float, description: str | None, date_value: date) -> PersonalDebt:
        return to_personal_debt(
            await self._service.create_personal_debt(
                person=person,
                total_amount=total_amount,
                description=description,
                date_value=date_value,
            )
        )

    async def update_personal_debt(self, debt_id: int, *, person: str, total_amount: float, description: str | None, date_value: date) -> PersonalDebt:
        return to_personal_debt(
            await self._service.update_personal_debt(
                debt_id,
                person=person,
                total_amount=total_amount,
                description=description,
                date_value=date_value,
            )
        )

    async def delete_personal_debt(self, debt_id: int) -> None:
        await self._service.delete_personal_debt(debt_id)

    async def add_personal_debt_payment(self, debt_id: int, *, payment_date: date, amount: float, notes: str | None) -> PersonalDebtPayment:
        return to_personal_debt_payment(
            await self._service.add_personal_debt_payment(
                debt_id,
                payment_date=payment_date,
                amount=amount,
                notes=notes,
            )
        )

    async def list_personal_debt_payments(self, debt_id: int) -> list[PersonalDebtPayment]:
        return [to_personal_debt_payment(item) for item in await self._service.list_personal_debt_payments(debt_id)]

    async def get_salary(self) -> float:
        return await self._service.get_salary()

    async def set_salary(self, amount: float) -> float:
        return await self._service.set_salary(amount)

    async def get_salary_override(self, year: int, month: int, cycle: int) -> float | None:
        return await self._service.get_salary_override(year, month, cycle)

    async def set_salary_override(self, year: int, month: int, cycle: int, amount: float) -> float:
        return await self._service.set_salary_override(year, month, cycle, amount)

    async def delete_salary_override(self, year: int, month: int, cycle: int) -> None:
        await self._service.delete_salary_override(year, month, cycle)

    async def get_total_savings(self) -> float:
        return await self._service.get_total_savings()

    async def get_period_savings(self, year: int, month: int, cycle: int) -> float:
        return await self._service.get_period_savings(year, month, cycle)

    async def add_savings(self, amount: float) -> float:
        row = await self._service.add_savings(amount)
        return float(row.total_saved)

    async def add_extra_savings(self, amount: float) -> float:
        row = await self._service.add_extra_savings(amount)
        return float(row.total_saved)

    async def withdraw_savings(self, amount: float) -> bool:
        return await self._service.withdraw_savings(amount)

    async def list_savings_goals(self) -> list[SavingsGoal]:
        return [to_savings_goal(item) for item in await self._service.list_savings_goals()]

    async def create_savings_goal(self, name: str, target_amount: float) -> SavingsGoal:
        return to_savings_goal(await self._service.create_savings_goal(name, target_amount))

    async def update_savings_goal(self, goal_id: int, name: str, target_amount: float) -> SavingsGoal:
        return to_savings_goal(await self._service.update_savings_goal(goal_id, name=name, target_amount=target_amount))

    async def delete_savings_goal(self, goal_id: int) -> None:
        await self._service.delete_savings_goal(goal_id)

    async def get_settings_payload(self) -> dict[str, object]:
        return await self._service.get_settings_payload()

    async def update_settings(self, *, period_mode: str | None = None, pay_day_1: int | None = None, pay_day_2: int | None = None, monthly_pay_day: int | None = None, theme: str | None = None, auto_export: bool | None = None, include_beta: bool | None = None) -> dict[str, object]:
        return await self._service.update_settings(
            period_mode=period_mode,
            pay_day_1=pay_day_1,
            pay_day_2=pay_day_2,
            monthly_pay_day=monthly_pay_day,
            theme=theme,
            auto_export=auto_export,
            include_beta=include_beta,
        )

    async def get_period_range(self, year: int, month: int, cycle: int) -> tuple[str, str]:
        return await self._service.get_period_range(year, month, cycle)

    async def get_cycle_for_date(self, value: date) -> int:
        return await self._service.get_cycle_for_date(value)

    async def get_custom_quincena(self, year: int, month: int, cycle: int) -> tuple[str, str]:
        return await self._service.get_custom_quincena(year, month, cycle)

    async def set_custom_quincena(self, year: int, month: int, cycle: int, start_date: date, end_date: date) -> tuple[str, str]:
        return await self._service.set_custom_quincena(year, month, cycle, start_date, end_date)

    async def delete_custom_quincena(self, year: int, month: int, cycle: int) -> None:
        await self._service.delete_custom_quincena(year, month, cycle)
