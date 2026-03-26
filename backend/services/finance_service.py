from __future__ import annotations

from dataclasses import asdict, dataclass
from datetime import date

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from backend.database.models import Category, Loan
from backend.repositories import (
    CategoryRepository,
    DebtRepository,
    ExpenseRepository,
    FixedPaymentRepository,
    IncomeRepository,
    LoanRepository,
    SavingsRepository,
    SettingsRepository,
)
from backend.services.period_service import PeriodService


DEFAULT_CATEGORIES = (
    "Comida",
    "Combustible",
    "Uber/Taxi",
    "Subscripciones",
    "Varios/Snacks",
    "Otros",
)


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
class DashboardResult:
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
    quincena_range: list[str]
    recent_items: list[dict[str, object]]
    fixed_payments: list[dict[str, object]]
    period_title: str


class FinanceError(Exception):
    pass


class FinanceService:
    def __init__(self, session: AsyncSession, user_id: int | None = None) -> None:
        self.session = session
        self.user_id = user_id
        self.category_repo = CategoryRepository(session)
        self.expense_repo = ExpenseRepository(session)
        self.fixed_payment_repo = FixedPaymentRepository(session)
        self.income_repo = IncomeRepository(session)
        self.loan_repo = LoanRepository(session)
        self.debt_repo = DebtRepository(session)
        self.savings_repo = SavingsRepository(session)
        self.settings_repo = SettingsRepository(session)

    def _uid(self, user_id: int | None = None) -> int:
        resolved = user_id if user_id is not None else self.user_id
        if resolved is None:
            raise FinanceError("User context is required.")
        return resolved

    async def ensure_default_categories(self, user_id: int | None = None) -> None:
        uid = self._uid(user_id)
        categories = await self.category_repo.list_by_user(uid)
        if categories:
            return
        for category_name in DEFAULT_CATEGORIES:
            await self.category_repo.create(uid, category_name)
        await self.session.flush()

    async def get_categories(self, user_id: int | None = None) -> list[Category]:
        uid = self._uid(user_id)
        await self.ensure_default_categories(uid)
        return await self.category_repo.list_by_user(uid)

    async def add_category(self, name: str, user_id: int | None = None) -> Category:
        uid = self._uid(user_id)
        normalized = name.strip()
        if not normalized:
            raise FinanceError("Category name is required.")
        if await self.category_repo.get_by_name(uid, normalized):
            raise FinanceError("Category already exists.")
        category = await self.category_repo.create(uid, normalized)
        await self.session.commit()
        return category

    async def rename_category(self, category_id: int, new_name: str, user_id: int | None = None) -> Category:
        uid = self._uid(user_id)
        category = await self.category_repo.get_by_id(category_id)
        if category is None or category.user_id != uid:
            raise FinanceError("Category not found.")
        updated = await self.category_repo.update(category_id, name=new_name.strip())
        await self.session.commit()
        return updated

    async def delete_category(self, category_id: int, user_id: int | None = None) -> None:
        uid = self._uid(user_id)
        category = await self.category_repo.get_by_id(category_id)
        if category is None or category.user_id != uid:
            raise FinanceError("Category not found.")
        if await self.expense_repo.count_category_usage(category_id) > 0:
            raise FinanceError("Category is in use by expenses.")
        if await self.fixed_payment_repo.count_active_category_usage(category_id) > 0:
            raise FinanceError("Category is in use by fixed payments.")
        await self.category_repo.delete(category_id)
        await self.session.commit()

    async def get_period_mode(self, user_id: int | None = None) -> str:
        return await self.settings_repo.get_period_mode(self._uid(user_id))

    async def get_quincenal_paydays(self, user_id: int | None = None) -> tuple[int, int]:
        uid = self._uid(user_id)
        day1 = int(await self.settings_repo.get_setting(uid, "quincenal_pay_day_1", "1") or 1)
        day2 = int(await self.settings_repo.get_setting(uid, "quincenal_pay_day_2", "16") or 16)
        if day1 == day2:
            day2 = 15 if day1 == 16 else 16
        return day1, day2

    async def get_monthly_payday(self, user_id: int | None = None) -> int:
        uid = self._uid(user_id)
        return int(await self.settings_repo.get_setting(uid, "monthly_pay_day", "1") or 1)

    async def get_quincena_range(self, year: int, month: int, cycle: int, user_id: int | None = None) -> tuple[str, str]:
        uid = self._uid(user_id)
        custom = await self.settings_repo.get_custom_quincena_range(uid, year, month, cycle)
        if custom is not None:
            return custom[0].isoformat(), custom[1].isoformat()
        day1, day2 = await self.get_quincenal_paydays(uid)
        bounds = PeriodService.get_quincena_range(year, month, cycle, day1=day1, day2=day2)
        return bounds.start.isoformat(), bounds.end.isoformat()

    async def get_period_range(self, year: int, month: int, cycle: int, user_id: int | None = None) -> tuple[str, str]:
        uid = self._uid(user_id)
        mode = await self.get_period_mode(uid)
        if mode == "mensual":
            bounds = PeriodService.get_month_range(year, month, await self.get_monthly_payday(uid))
            return bounds.start.isoformat(), bounds.end.isoformat()
        return await self.get_quincena_range(year, month, cycle, uid)

    async def get_cycle_for_date(self, value: date, user_id: int | None = None) -> int:
        uid = self._uid(user_id)
        mode = await self.get_period_mode(uid)
        if mode == "mensual":
            return 1
        day1, day2 = await self.get_quincenal_paydays(uid)
        return PeriodService.get_cycle_for_date(value, period_mode=mode, day1=day1, day2=day2)

    async def add_expense(
        self,
        *,
        amount: float,
        description: str,
        category_id: int,
        date_value: date,
        source: str = "sueldo",
        user_id: int | None = None,
    ):
        uid = self._uid(user_id)
        cycle = await self.get_cycle_for_date(date_value, uid)
        status = "completed_savings" if source.strip().lower() == "ahorro" else "completed_salary"
        item = await self.expense_repo.create(
            user_id=uid,
            amount=amount,
            description=description.strip(),
            date_value=date_value,
            quincenal_cycle=cycle,
            category_ids=[category_id],
            status=status,
        )
        await self.session.commit()
        return item

    async def list_expenses(self, start_date: date, end_date: date, user_id: int | None = None):
        return await self.expense_repo.list_by_range(self._uid(user_id), start_date, end_date)

    async def update_expense(
        self,
        expense_id: int,
        *,
        amount: float,
        description: str,
        category_id: int,
        date_value: date,
        user_id: int | None = None,
    ):
        uid = self._uid(user_id)
        expense = await self.expense_repo.get_by_id(expense_id)
        if expense is None or expense.user_id != uid:
            raise FinanceError("Expense not found.")
        cycle = await self.get_cycle_for_date(date_value, uid)
        item = await self.expense_repo.update(
            expense_id,
            amount=amount,
            description=description.strip(),
            date_value=date_value,
            quincenal_cycle=cycle,
            category_ids=[category_id],
        )
        await self.session.commit()
        return item

    async def delete_expense(self, expense_id: int, user_id: int | None = None) -> None:
        uid = self._uid(user_id)
        expense = await self.expense_repo.get_by_id(expense_id)
        if expense is None or expense.user_id != uid:
            raise FinanceError("Expense not found.")
        await self.expense_repo.delete(expense_id)
        await self.session.commit()

    async def add_fixed_payment(
        self,
        *,
        name: str,
        amount: float,
        due_day: int,
        category_id: int | None,
        no_fixed_date: bool = False,
        user_id: int | None = None,
    ):
        uid = self._uid(user_id)
        item = await self.fixed_payment_repo.create(
            user_id=uid,
            name=name.strip(),
            amount=amount,
            due_day=0 if no_fixed_date else due_day,
            category_id=category_id,
        )
        await self.session.commit()
        return item

    async def update_fixed_payment(
        self,
        payment_id: int,
        *,
        name: str,
        amount: float,
        due_day: int,
        category_id: int | None,
        no_fixed_date: bool = False,
        user_id: int | None = None,
    ):
        uid = self._uid(user_id)
        payment = await self.fixed_payment_repo.get_by_id(payment_id)
        if payment is None or payment.user_id != uid:
            raise FinanceError("Fixed payment not found.")
        item = await self.fixed_payment_repo.update(
            payment_id,
            name=name.strip(),
            amount=amount,
            due_day=0 if no_fixed_date else due_day,
            category_id=category_id,
            update_category=True,
        )
        await self.session.commit()
        return item

    async def delete_fixed_payment(self, payment_id: int, user_id: int | None = None) -> None:
        uid = self._uid(user_id)
        payment = await self.fixed_payment_repo.get_by_id(payment_id)
        if payment is None or payment.user_id != uid:
            raise FinanceError("Fixed payment not found.")
        await self.fixed_payment_repo.soft_delete(payment_id)
        await self.session.commit()

    async def set_fixed_payment_paid(
        self,
        payment_id: int,
        year: int,
        month: int,
        cycle: int,
        paid: bool,
        user_id: int | None = None,
    ) -> FixedPaymentStatus:
        uid = self._uid(user_id)
        payment = await self.fixed_payment_repo.get_by_id(payment_id)
        if payment is None or payment.user_id != uid:
            raise FinanceError("Fixed payment not found.")
        await self.fixed_payment_repo.set_record_status(payment_id, year, month, cycle, paid)
        await self.session.commit()
        items = await self.get_fixed_payments_for_period(year, month, cycle, uid)
        return next(item for item in items if item.id == payment_id)

    async def get_fixed_payments_for_period(self, year: int, month: int, cycle: int, user_id: int | None = None) -> list[FixedPaymentStatus]:
        uid = self._uid(user_id)
        payments = await self.fixed_payment_repo.list_active_by_user(uid)
        start_iso, end_iso = await self.get_period_range(year, month, cycle, uid)
        start = date.fromisoformat(start_iso)
        end = date.fromisoformat(end_iso)
        today = date.today()
        out: list[FixedPaymentStatus] = []
        for payment in payments:
            if payment.due_day <= 0:
                status = await self.fixed_payment_repo.get_record_status(payment.id, year, month, cycle, default_status="pending")
                out.append(FixedPaymentStatus(payment.id, payment.name, float(payment.amount), payment.due_day, payment.category_id, status == "paid", False, ""))
                continue
            for target_year, target_month in PeriodService.iterate_months(start, end):
                due = date(target_year, target_month, PeriodService.safe_day(target_year, target_month, payment.due_day))
                if due < start or due > end:
                    continue
                status = await self.fixed_payment_repo.get_record_status(payment.id, year, month, cycle, default_status="paid")
                is_paid = status == "paid"
                out.append(FixedPaymentStatus(payment.id, payment.name, float(payment.amount), payment.due_day, payment.category_id, is_paid, due <= today, due.isoformat()))
                break
        out.sort(key=lambda item: (item.due_date != "", item.due_date, item.name.lower()))
        return out

    async def add_income(self, *, amount: float, description: str, date_value: date, user_id: int | None = None):
        item = await self.income_repo.create(
            user_id=self._uid(user_id),
            amount=amount,
            description=description.strip(),
            date_value=date_value,
        )
        await self.session.commit()
        return item

    async def list_income(self, start_date: date, end_date: date, user_id: int | None = None):
        return await self.income_repo.list_by_range(self._uid(user_id), start_date, end_date)

    async def update_income(
        self,
        income_id: int,
        *,
        amount: float,
        description: str,
        date_value: date,
        user_id: int | None = None,
    ):
        uid = self._uid(user_id)
        income = await self.income_repo.get_by_id(income_id)
        if income is None or income.user_id != uid:
            raise FinanceError("Income item not found.")
        item = await self.income_repo.update(income_id, amount=amount, description=description.strip(), date_value=date_value)
        await self.session.commit()
        return item

    async def delete_income(self, income_id: int, user_id: int | None = None) -> None:
        uid = self._uid(user_id)
        income = await self.income_repo.get_by_id(income_id)
        if income is None or income.user_id != uid:
            raise FinanceError("Income item not found.")
        await self.income_repo.delete(income_id)
        await self.session.commit()

    async def set_salary(self, amount: float, user_id: int | None = None) -> float:
        await self.settings_repo.set_salary(self._uid(user_id), amount)
        await self.session.commit()
        return amount

    async def get_salary(self, user_id: int | None = None) -> float:
        return await self.settings_repo.get_salary(self._uid(user_id))

    async def set_salary_override(self, year: int, month: int, cycle: int, amount: float, user_id: int | None = None) -> float:
        await self.settings_repo.set_salary_override(self._uid(user_id), year, month, cycle, amount)
        await self.session.commit()
        return amount

    async def get_salary_override(self, year: int, month: int, cycle: int, user_id: int | None = None) -> float | None:
        return await self.settings_repo.get_salary_override(self._uid(user_id), year, month, cycle)

    async def delete_salary_override(self, year: int, month: int, cycle: int, user_id: int | None = None) -> None:
        await self.settings_repo.delete_salary_override(self._uid(user_id), year, month, cycle)
        await self.session.commit()

    async def get_salary_for_period(self, year: int, month: int, cycle: int, user_id: int | None = None) -> float:
        override = await self.get_salary_override(year, month, cycle, user_id)
        return override if override is not None else await self.get_salary(user_id)

    async def add_savings(self, amount: float, when: date | None = None, user_id: int | None = None):
        uid = self._uid(user_id)
        today = when or date.today()
        cycle = await self.get_cycle_for_date(today, uid)
        row = await self.savings_repo.record_savings(uid, amount, today.year, today.month, cycle)
        await self.session.commit()
        return row

    async def add_extra_savings(self, amount: float, when: date | None = None, user_id: int | None = None):
        uid = self._uid(user_id)
        today = when or date.today()
        cycle = await self.get_cycle_for_date(today, uid)
        row = await self.savings_repo.add_extra_savings(uid, amount, today.year, today.month, cycle)
        await self.session.commit()
        return row

    async def withdraw_savings(self, amount: float, user_id: int | None = None) -> bool:
        ok = await self.savings_repo.withdraw_savings(self._uid(user_id), amount)
        await self.session.commit()
        return ok

    async def get_period_savings(self, year: int, month: int, cycle: int, user_id: int | None = None) -> float:
        row = await self.savings_repo.get_by_period(self._uid(user_id), year, month, cycle)
        return float(row.last_quincenal_savings or 0) if row else 0.0

    async def get_total_savings(self, user_id: int | None = None) -> float:
        return await self.savings_repo.get_total_savings(self._uid(user_id))

    async def add_savings_goal(self, name: str, target_amount: float, user_id: int | None = None):
        goal = await self.savings_repo.create_goal(self._uid(user_id), name.strip(), target_amount)
        await self.session.commit()
        return goal

    async def create_savings_goal(self, name: str, target_amount: float, user_id: int | None = None):
        return await self.add_savings_goal(name, target_amount, user_id)

    async def list_savings_goals(self, user_id: int | None = None):
        return await self.savings_repo.list_goals(self._uid(user_id))

    async def update_savings_goal(self, goal_id: int, *, name: str, target_amount: float, user_id: int | None = None):
        uid = self._uid(user_id)
        goal = await self.savings_repo.get_goal(goal_id)
        if goal is None or goal.user_id != uid:
            raise FinanceError("Savings goal not found.")
        item = await self.savings_repo.update_goal(goal_id, name=name.strip(), target_amount=target_amount)
        await self.session.commit()
        return item

    async def delete_savings_goal(self, goal_id: int, user_id: int | None = None) -> None:
        uid = self._uid(user_id)
        goal = await self.savings_repo.get_goal(goal_id)
        if goal is None or goal.user_id != uid:
            raise FinanceError("Savings goal not found.")
        await self.savings_repo.delete_goal(goal_id)
        await self.session.commit()

    async def get_settings_payload(self, user_id: int | None = None) -> dict[str, object]:
        uid = self._uid(user_id)
        raw = await self.settings_repo.get_all_settings(uid)
        return {
            "period_mode": await self.get_period_mode(uid),
            "pay_day_1": int(raw.get("quincenal_pay_day_1", "1")),
            "pay_day_2": int(raw.get("quincenal_pay_day_2", "16")),
            "monthly_pay_day": int(raw.get("monthly_pay_day", "1")),
            "theme": raw.get("theme_preset", "classic_flet"),
            "auto_export": raw.get("auto_export_close_period", "false").lower() == "true",
            "include_beta": raw.get("include_beta_updates", "false").lower() == "true",
        }

    async def update_settings_payload(self, payload: dict[str, object], user_id: int | None = None) -> dict[str, object]:
        uid = self._uid(user_id)
        current = await self.get_settings_payload(uid)
        merged = {**current, **payload}
        await self.settings_repo.set_period_mode(uid, str(merged["period_mode"]))
        await self.settings_repo.set_setting(uid, "quincenal_pay_day_1", str(merged["pay_day_1"]))
        await self.settings_repo.set_setting(uid, "quincenal_pay_day_2", str(merged["pay_day_2"]))
        await self.settings_repo.set_setting(uid, "monthly_pay_day", str(merged["monthly_pay_day"]))
        await self.settings_repo.set_setting(uid, "theme_preset", str(merged["theme"]))
        await self.settings_repo.set_setting(uid, "auto_export_close_period", str(bool(merged["auto_export"])).lower())
        await self.settings_repo.set_setting(uid, "include_beta_updates", str(bool(merged["include_beta"])).lower())
        await self.session.commit()
        return await self.get_settings_payload(uid)

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
        user_id: int | None = None,
    ) -> dict[str, object]:
        payload: dict[str, object] = {}
        if period_mode is not None:
            payload["period_mode"] = period_mode
        if pay_day_1 is not None:
            payload["pay_day_1"] = pay_day_1
        if pay_day_2 is not None:
            payload["pay_day_2"] = pay_day_2
        if monthly_pay_day is not None:
            payload["monthly_pay_day"] = monthly_pay_day
        if theme is not None:
            payload["theme"] = theme
        if auto_export is not None:
            payload["auto_export"] = auto_export
        if include_beta is not None:
            payload["include_beta"] = include_beta
        return await self.update_settings_payload(payload, user_id)

    async def get_custom_quincena(self, year: int, month: int, cycle: int, user_id: int | None = None) -> tuple[str, str]:
        custom = await self.settings_repo.get_custom_quincena_range(self._uid(user_id), year, month, cycle)
        if custom is not None:
            return custom[0].isoformat(), custom[1].isoformat()
        return await self.get_period_range(year, month, cycle, user_id)

    async def set_custom_quincena(self, year: int, month: int, cycle: int, start_date: date, end_date: date, user_id: int | None = None) -> tuple[str, str]:
        await self.settings_repo.set_custom_quincena(self._uid(user_id), year, month, cycle, start_date, end_date)
        await self.session.commit()
        return start_date.isoformat(), end_date.isoformat()

    async def delete_custom_quincena(self, year: int, month: int, cycle: int, user_id: int | None = None) -> None:
        await self.settings_repo.delete_custom_quincena(self._uid(user_id), year, month, cycle)
        await self.session.commit()

    async def get_dashboard_data(self, year: int | None = None, month: int | None = None, cycle: int | None = None, user_id: int | None = None) -> DashboardResult:
        uid = self._uid(user_id)
        await self.ensure_default_categories(uid)
        today = date.today()
        target_year = year or today.year
        target_month = month or today.month
        target_cycle = cycle or await self.get_cycle_for_date(today, uid)
        start_iso, end_iso = await self.get_period_range(target_year, target_month, target_cycle, uid)
        start_date = date.fromisoformat(start_iso)
        end_date = date.fromisoformat(end_iso)
        period_mode = await self.get_period_mode(uid)
        expenses = await self.expense_repo.list_by_range(uid, start_date, end_date)
        fixed_payments = await self.get_fixed_payments_for_period(target_year, target_month, target_cycle, uid)
        total_savings = await self.get_total_savings(uid)
        period_savings = await self.get_period_savings(target_year, target_month, target_cycle, uid)
        salary = await self.get_salary(uid) if period_mode == "mensual" else await self.get_salary_for_period(target_year, target_month, target_cycle, uid)
        extra_income = await self.income_repo.get_total_by_range(uid, start_date, end_date)
        total_loans = await self.get_total_loans_affecting_budget(uid)
        total_expenses = sum(float(item.amount) for item in expenses)
        total_expenses_salary = sum(float(item.amount) for item in expenses if item.status.strip().lower() != "completed_savings")
        total_expenses_savings = total_expenses - total_expenses_salary
        total_fixed = sum(item.amount for item in fixed_payments)
        dinero_inicial = salary + extra_income - period_savings
        dinero_disponible = dinero_inicial - total_expenses_salary - total_fixed - total_loans

        daily: dict[str, float] = {}
        cat_totals: dict[str, float] = {}
        recent_items: list[dict[str, object]] = []
        categories = await self.get_categories(uid)
        categories_by_id = {category.id: category.name for category in categories}
        for expense in expenses:
            key = expense.date.isoformat()
            daily[key] = daily.get(key, 0.0) + float(expense.amount)
            category_ids = [category.id for category in expense.categories]
            for category_id in category_ids:
                str_id = str(category_id)
                cat_totals[str_id] = cat_totals.get(str_id, 0.0) + float(expense.amount)
            recent_items.append(
                {
                    "date": expense.date.isoformat(),
                    "description": expense.description,
                    "amount": float(expense.amount),
                    "categories": ", ".join(categories_by_id.get(category_id, "Sin cat.") for category_id in category_ids) or "Sin cat.",
                    "type": "expense",
                    "id": expense.id,
                }
            )
        for fixed in fixed_payments:
            if fixed.due_day <= 0:
                if not fixed.is_paid:
                    continue
                recent_items.append(
                    {
                        "date": today.isoformat(),
                        "description": f"Pago fijo pagado: {fixed.name}",
                        "amount": fixed.amount,
                        "categories": "Pago fijo",
                        "type": "fixed_due",
                        "id": fixed.id,
                    }
                )
                continue
            if fixed.is_paid and fixed.due_date and fixed.due_date <= today.isoformat():
                recent_items.append(
                    {
                        "date": fixed.due_date,
                        "description": f"Pago fijo: {fixed.name}",
                        "amount": fixed.amount,
                        "categories": "Pago fijo",
                        "type": "fixed_due",
                        "id": fixed.id,
                    }
                )
        recent_items.sort(key=lambda item: str(item["date"]), reverse=True)
        avg_daily = 0.0 if not daily else sum(daily.values()) / len(daily)
        return DashboardResult(
            year=target_year,
            month=target_month,
            cycle=target_cycle,
            period_mode=period_mode,
            salary=salary,
            extra_income=extra_income,
            period_savings=period_savings,
            total_savings=total_savings,
            dinero_inicial=dinero_inicial,
            total_expenses=total_expenses,
            total_expenses_salary=total_expenses_salary,
            total_expenses_savings=total_expenses_savings,
            total_fixed=total_fixed,
            total_loans=total_loans,
            dinero_disponible=dinero_disponible,
            avg_daily=avg_daily,
            expense_count=len(expenses),
            fixed_count=len(fixed_payments),
            cat_totals=cat_totals,
            quincena_range=[start_iso, end_iso],
            recent_items=recent_items[:20],
            fixed_payments=[asdict(item) for item in fixed_payments],
            period_title=PeriodService.format_period_label(
                year=target_year,
                month=target_month,
                cycle=target_cycle,
                period_mode=period_mode,
                start_date=start_iso,
                end_date=end_iso,
            ),
        )


    def _normalize_deduction_type(self, value: str | None) -> str:
        normalized = (value or "ninguno").strip().lower()
        if normalized not in {"ninguno", "gasto", "ahorro"}:
            raise FinanceError("deduction_type debe ser ninguno, gasto o ahorro.")
        return normalized

    def _calculate_monthly_payment(self, principal_amount: float, annual_rate: float, term_months: int) -> float:
        if term_months <= 0:
            raise FinanceError("term_months debe ser mayor a 0.")
        if annual_rate <= 0:
            return round(principal_amount / term_months, 2)
        monthly_rate = annual_rate / 100 / 12
        payment = principal_amount * monthly_rate / (1 - (1 + monthly_rate) ** (-term_months))
        return round(payment, 2)

    async def add_loan(
        self,
        *,
        person: str,
        amount: float,
        description: str | None,
        date_value: date,
        deduction_type: str = "ninguno",
        user_id: int | None = None,
    ):
        uid = self._uid(user_id)
        normalized_person = person.strip()
        if not normalized_person:
            raise FinanceError("Person is required.")
        normalized_deduction = self._normalize_deduction_type(deduction_type)
        if normalized_deduction == "ahorro":
            ok = await self.savings_repo.withdraw_savings(uid, amount)
            if not ok:
                raise FinanceError("Insufficient savings for this loan.")
        elif normalized_deduction == "gasto":
            await self.ensure_default_categories(uid)
            category = await self.category_repo.get_by_name(uid, "Otros")
            if category is None:
                category = await self.category_repo.create(uid, "Otros")
            cycle = await self.get_cycle_for_date(date_value, uid)
            await self.expense_repo.create(
                user_id=uid,
                amount=amount,
                description=(description or f"Prestamo a {normalized_person}").strip(),
                date_value=date_value,
                quincenal_cycle=cycle,
                category_ids=[category.id],
                status="completed_salary",
            )
        item = await self.loan_repo.create(
            user_id=uid,
            person=normalized_person,
            amount=amount,
            description=description.strip() if description else None,
            date_value=date_value,
            deduction_type=normalized_deduction,
        )
        await self.session.commit()
        return item

    async def list_loans(self, *, include_paid: bool = False, user_id: int | None = None):
        return await self.loan_repo.list_by_user(self._uid(user_id), include_paid=include_paid)

    async def update_loan(
        self,
        loan_id: int,
        *,
        person: str,
        amount: float,
        description: str | None,
        date_value: date,
        deduction_type: str,
        user_id: int | None = None,
    ):
        uid = self._uid(user_id)
        item = await self.loan_repo.get_by_id(loan_id)
        if item is None or item.user_id != uid:
            raise FinanceError("Loan not found.")
        updated = await self.loan_repo.update(
            loan_id,
            person=person.strip(),
            amount=amount,
            description=description.strip() if description else None,
            date_value=date_value,
            deduction_type=self._normalize_deduction_type(deduction_type),
        )
        await self.session.commit()
        return updated

    async def delete_loan(self, loan_id: int, user_id: int | None = None) -> None:
        uid = self._uid(user_id)
        item = await self.loan_repo.get_by_id(loan_id)
        if item is None or item.user_id != uid:
            raise FinanceError("Loan not found.")
        await self.loan_repo.delete(loan_id)
        await self.session.commit()

    async def pay_loan(self, loan_id: int, user_id: int | None = None):
        uid = self._uid(user_id)
        item = await self.loan_repo.get_by_id(loan_id)
        if item is None or item.user_id != uid:
            raise FinanceError("Loan not found.")
        updated = await self.loan_repo.update(loan_id, is_paid=True, paid_date=date.today())
        await self.session.commit()
        return updated

    async def create_debt(
        self,
        *,
        name: str,
        principal_amount: float,
        annual_rate: float,
        term_months: int,
        start_date: date,
        payment_day: int,
        user_id: int | None = None,
    ):
        uid = self._uid(user_id)
        monthly_payment = self._calculate_monthly_payment(principal_amount, annual_rate, term_months)
        item = await self.debt_repo.create_debt(
            user_id=uid,
            name=name.strip(),
            principal_amount=principal_amount,
            annual_rate=annual_rate,
            term_months=term_months,
            start_date=start_date,
            payment_day=payment_day,
            monthly_payment=monthly_payment,
            current_balance=principal_amount,
        )
        await self.session.commit()
        return item

    async def list_debts(self, *, include_inactive: bool = False, user_id: int | None = None):
        return await self.debt_repo.list_debts(self._uid(user_id), include_inactive=include_inactive)

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
        user_id: int | None = None,
    ):
        uid = self._uid(user_id)
        item = await self.debt_repo.get_debt(debt_id)
        if item is None or item.user_id != uid:
            raise FinanceError("Debt not found.")
        monthly_payment = self._calculate_monthly_payment(principal_amount, annual_rate, term_months)
        current_balance = min(float(item.current_balance), principal_amount)
        updated = await self.debt_repo.update_debt(
            debt_id,
            name=name.strip(),
            principal_amount=principal_amount,
            annual_rate=annual_rate,
            term_months=term_months,
            start_date=start_date,
            payment_day=payment_day,
            monthly_payment=monthly_payment,
            current_balance=current_balance,
        )
        await self.session.commit()
        return updated

    async def delete_debt(self, debt_id: int, user_id: int | None = None) -> None:
        uid = self._uid(user_id)
        item = await self.debt_repo.get_debt(debt_id)
        if item is None or item.user_id != uid:
            raise FinanceError("Debt not found.")
        await self.debt_repo.delete_debt(debt_id)
        await self.session.commit()

    async def add_debt_payment(
        self,
        debt_id: int,
        *,
        payment_date: date,
        total_amount: float,
        interest_amount: float,
        capital_amount: float,
        notes: str | None = None,
        user_id: int | None = None,
    ):
        uid = self._uid(user_id)
        item = await self.debt_repo.get_debt(debt_id)
        if item is None or item.user_id != uid:
            raise FinanceError("Debt not found.")
        if interest_amount + capital_amount > total_amount + 0.0001:
            raise FinanceError("Payment breakdown exceeds total amount.")
        if capital_amount > float(item.current_balance) + 0.0001:
            raise FinanceError("Capital amount exceeds current balance.")
        payment = await self.debt_repo.create_debt_payment(
            debt_id=debt_id,
            payment_date=payment_date,
            total_amount=total_amount,
            interest_amount=interest_amount,
            capital_amount=capital_amount,
            notes=notes.strip() if notes else None,
        )
        new_balance = max(0.0, float(item.current_balance) - capital_amount)
        await self.debt_repo.update_debt(debt_id, current_balance=new_balance, is_active=new_balance > 0)
        await self.session.commit()
        return payment

    async def list_debt_payments(self, debt_id: int, user_id: int | None = None):
        uid = self._uid(user_id)
        item = await self.debt_repo.get_debt(debt_id)
        if item is None or item.user_id != uid:
            raise FinanceError("Debt not found.")
        return await self.debt_repo.list_debt_payments(debt_id)

    async def create_personal_debt(
        self,
        *,
        person: str,
        total_amount: float,
        description: str | None,
        date_value: date,
        user_id: int | None = None,
    ):
        uid = self._uid(user_id)
        item = await self.debt_repo.create_personal_debt(
            user_id=uid,
            person=person.strip(),
            total_amount=total_amount,
            current_balance=total_amount,
            description=description.strip() if description else None,
            date_value=date_value,
        )
        await self.session.commit()
        return item

    async def list_personal_debts(self, *, include_paid: bool = False, user_id: int | None = None):
        return await self.debt_repo.list_personal_debts(self._uid(user_id), include_paid=include_paid)

    async def update_personal_debt(
        self,
        debt_id: int,
        *,
        person: str,
        total_amount: float,
        description: str | None,
        date_value: date,
        user_id: int | None = None,
    ):
        uid = self._uid(user_id)
        item = await self.debt_repo.get_personal_debt(debt_id)
        if item is None or item.user_id != uid:
            raise FinanceError("Personal debt not found.")
        current_balance = min(float(item.current_balance), total_amount)
        updated = await self.debt_repo.update_personal_debt(
            debt_id,
            person=person.strip(),
            total_amount=total_amount,
            current_balance=current_balance,
            description=description.strip() if description else None,
            date_value=date_value,
        )
        await self.session.commit()
        return updated

    async def delete_personal_debt(self, debt_id: int, user_id: int | None = None) -> None:
        uid = self._uid(user_id)
        item = await self.debt_repo.get_personal_debt(debt_id)
        if item is None or item.user_id != uid:
            raise FinanceError("Personal debt not found.")
        await self.debt_repo.delete_personal_debt(debt_id)
        await self.session.commit()

    async def add_personal_debt_payment(
        self,
        debt_id: int,
        *,
        payment_date: date,
        amount: float,
        notes: str | None = None,
        user_id: int | None = None,
    ):
        uid = self._uid(user_id)
        item = await self.debt_repo.get_personal_debt(debt_id)
        if item is None or item.user_id != uid:
            raise FinanceError("Personal debt not found.")
        if amount > float(item.current_balance) + 0.0001:
            raise FinanceError("Payment amount exceeds current balance.")
        payment = await self.debt_repo.create_personal_debt_payment(
            personal_debt_id=debt_id,
            payment_date=payment_date,
            amount=amount,
            notes=notes.strip() if notes else None,
        )
        new_balance = max(0.0, float(item.current_balance) - amount)
        await self.debt_repo.update_personal_debt(
            debt_id,
            current_balance=new_balance,
            is_paid=new_balance <= 0,
            paid_date=date.today() if new_balance <= 0 else None,
        )
        await self.session.commit()
        return payment

    async def list_personal_debt_payments(self, debt_id: int, user_id: int | None = None):
        uid = self._uid(user_id)
        item = await self.debt_repo.get_personal_debt(debt_id)
        if item is None or item.user_id != uid:
            raise FinanceError("Personal debt not found.")
        return await self.debt_repo.list_personal_debt_payments(debt_id)
    async def get_total_loans_affecting_budget(self, user_id: int | None = None) -> float:
        uid = self._uid(user_id)
        stmt = select(func.coalesce(func.sum(Loan.amount), 0.0)).where(
            Loan.user_id == uid,
            Loan.is_paid.is_(False),
            or_(Loan.deduction_type.is_(None), Loan.deduction_type == "ninguno"),
        )
        return float((await self.session.scalar(stmt)) or 0.0)
