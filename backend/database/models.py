from __future__ import annotations

from datetime import date, datetime

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.database.base import Base


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )


class UpdatedAtMixin:
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now(), nullable=False
    )


class User(Base, TimestampMixin):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    username: Mapped[str] = mapped_column(String(120), unique=True, nullable=False)
    email: Mapped[str | None] = mapped_column(String(255))
    password_hash: Mapped[str | None] = mapped_column(String(255))
    pin_hash: Mapped[str | None] = mapped_column(String(255))
    pin_length: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    categories: Mapped[list[Category]] = relationship(back_populates="user")
    expenses: Mapped[list[Expense]] = relationship(back_populates="user")
    fixed_payments: Mapped[list[FixedPayment]] = relationship(back_populates="user")
    extra_income: Mapped[list[ExtraIncome]] = relationship(back_populates="user")
    savings_entries: Mapped[list[Savings]] = relationship(back_populates="user")
    savings_goals: Mapped[list[SavingsGoal]] = relationship(back_populates="user")
    loans: Mapped[list[Loan]] = relationship(back_populates="user")
    debts: Mapped[list[Debt]] = relationship(back_populates="user")
    personal_debts: Mapped[list[PersonalDebt]] = relationship(back_populates="user")
    salary: Mapped[UserSalary | None] = relationship(back_populates="user", uselist=False)
    salary_overrides: Mapped[list[SalaryOverride]] = relationship(back_populates="user")
    period_mode: Mapped[UserPeriodMode | None] = relationship(
        back_populates="user", uselist=False
    )
    settings: Mapped[list[UserSetting]] = relationship(back_populates="user")
    custom_quincenas: Mapped[list[CustomQuincena]] = relationship(back_populates="user")
    subscriptions: Mapped[list[Subscription]] = relationship(back_populates="user")
    sessions: Mapped[list[SessionToken]] = relationship(back_populates="user")


class OtpChallenge(Base, TimestampMixin):
    __tablename__ = "otp_challenges"
    __table_args__ = (
        Index("idx_otp_challenges_lookup", "email", "purpose", "expires_at"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    email: Mapped[str] = mapped_column(String(255), nullable=False)
    purpose: Mapped[str] = mapped_column(String(40), nullable=False)
    username: Mapped[str] = mapped_column(String(120), nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    pin_hash: Mapped[str | None] = mapped_column(String(255))
    pin_length: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    code_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    consumed_at: Mapped[datetime | None] = mapped_column(DateTime)
    attempt_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)


class AppSetting(Base):
    __tablename__ = "app_settings"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    setting_key: Mapped[str] = mapped_column(String(120), unique=True, nullable=False)
    setting_value: Mapped[str] = mapped_column(Text, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now(), nullable=False
    )


class Category(Base, TimestampMixin):
    __tablename__ = "categories"
    __table_args__ = (UniqueConstraint("user_id", "name", name="uq_categories_user_name"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    color: Mapped[str | None] = mapped_column(String(32))
    icon: Mapped[str | None] = mapped_column(String(64))

    user: Mapped[User] = relationship(back_populates="categories")
    expenses: Mapped[list[Expense]] = relationship(
        secondary="expense_categories",
        back_populates="categories",
        overlaps="expense_categories,category",
    )
    expense_categories: Mapped[list[ExpenseCategory]] = relationship(
        back_populates="category",
        overlaps="expenses,categories",
    )
    fixed_payments: Mapped[list[FixedPayment]] = relationship(back_populates="category")


class Budget(Base, TimestampMixin):
    __tablename__ = "budgets"
    __table_args__ = (
        UniqueConstraint(
            "user_id", "category_id", "quincenal_cycle", "year", "month",
            name="uq_budgets_user_category_period",
        ),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    category_id: Mapped[int] = mapped_column(ForeignKey("categories.id"), nullable=False)
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    quincenal_cycle: Mapped[int] = mapped_column(Integer, nullable=False)
    year: Mapped[int] = mapped_column(Integer, nullable=False)
    month: Mapped[int] = mapped_column(Integer, nullable=False)


class Expense(Base, TimestampMixin, UpdatedAtMixin):
    __tablename__ = "expenses"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    description: Mapped[str] = mapped_column(String(255), nullable=False)
    date: Mapped[date] = mapped_column(Date, nullable=False)
    quincenal_cycle: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[str] = mapped_column(String(40), default="pending", nullable=False)

    user: Mapped[User] = relationship(back_populates="expenses")
    categories: Mapped[list[Category]] = relationship(
        secondary="expense_categories",
        back_populates="expenses",
        lazy="selectin",
        overlaps="expense_categories,category",
    )
    expense_categories: Mapped[list[ExpenseCategory]] = relationship(
        back_populates="expense",
        cascade="all, delete-orphan",
        overlaps="expenses,categories",
    )


class ExpenseCategory(Base, TimestampMixin):
    __tablename__ = "expense_categories"
    __table_args__ = (
        UniqueConstraint("expense_id", "category_id", name="uq_expense_category"),
    )
    __mapper_args__ = {"confirm_deleted_rows": False}

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    expense_id: Mapped[int] = mapped_column(
        ForeignKey("expenses.id", ondelete="CASCADE"), nullable=False
    )
    category_id: Mapped[int] = mapped_column(ForeignKey("categories.id"), nullable=False)

    expense: Mapped[Expense] = relationship(
        back_populates="expense_categories",
        overlaps="expenses,categories",
    )
    category: Mapped[Category] = relationship(
        back_populates="expense_categories",
        overlaps="expenses,categories",
    )


class FixedPayment(Base, TimestampMixin, UpdatedAtMixin):
    __tablename__ = "fixed_payments"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(160), nullable=False)
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    category_id: Mapped[int | None] = mapped_column(ForeignKey("categories.id"))
    due_day: Mapped[int] = mapped_column(Integer, nullable=False)
    frequency: Mapped[str] = mapped_column(String(40), default="monthly", nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    user: Mapped[User] = relationship(back_populates="fixed_payments")
    category: Mapped[Category | None] = relationship(back_populates="fixed_payments")
    records: Mapped[list[FixedPaymentRecord]] = relationship(back_populates="fixed_payment")


class FixedPaymentRecord(Base, TimestampMixin):
    __tablename__ = "fixed_payment_records"
    __table_args__ = (
        Index("idx_fixed_payment_records_lookup", "fixed_payment_id", "year", "month"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    fixed_payment_id: Mapped[int] = mapped_column(ForeignKey("fixed_payments.id"), nullable=False)
    expense_id: Mapped[int | None] = mapped_column(ForeignKey("expenses.id"))
    year: Mapped[int] = mapped_column(Integer, nullable=False)
    month: Mapped[int] = mapped_column(Integer, nullable=False)
    quincenal_cycle: Mapped[int | None] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(40), default="pending", nullable=False)
    paid_date: Mapped[date | None] = mapped_column(Date)

    fixed_payment: Mapped[FixedPayment] = relationship(back_populates="records")


class ExtraIncome(Base, TimestampMixin):
    __tablename__ = "extra_income"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    description: Mapped[str] = mapped_column(String(255), nullable=False)
    date: Mapped[date] = mapped_column(Date, nullable=False)
    income_type: Mapped[str] = mapped_column(String(60), default="bonus", nullable=False)

    user: Mapped[User] = relationship(back_populates="extra_income")


class Savings(Base, TimestampMixin, UpdatedAtMixin):
    __tablename__ = "savings"
    __table_args__ = (
        UniqueConstraint("user_id", "year", "month", "quincenal_cycle", name="uq_savings_period"),
        Index("idx_savings_user_period", "user_id", "year", "month", "quincenal_cycle"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    total_saved: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    last_quincenal_savings: Mapped[float | None] = mapped_column(Float)
    year: Mapped[int] = mapped_column(Integer, nullable=False)
    month: Mapped[int] = mapped_column(Integer, nullable=False)
    quincenal_cycle: Mapped[int] = mapped_column(Integer, nullable=False)

    user: Mapped[User] = relationship(back_populates="savings_entries")


class Backup(Base):
    __tablename__ = "backups"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    backup_file: Mapped[str] = mapped_column(String(255), nullable=False)
    backup_date: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)


class Loan(Base, TimestampMixin):
    __tablename__ = "loans"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    person: Mapped[str] = mapped_column(String(160), nullable=False)
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    description: Mapped[str | None] = mapped_column(String(255))
    date: Mapped[date] = mapped_column(Date, nullable=False)
    is_paid: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    paid_date: Mapped[date | None] = mapped_column(Date)
    deduction_type: Mapped[str] = mapped_column(String(40), default="ninguno", nullable=False)

    user: Mapped[User] = relationship(back_populates="loans")


class SavingsGoal(Base, TimestampMixin):
    __tablename__ = "savings_goals"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(160), nullable=False)
    target_amount: Mapped[float] = mapped_column(Float, nullable=False)

    user: Mapped[User] = relationship(back_populates="savings_goals")


class Debt(Base, TimestampMixin, UpdatedAtMixin):
    __tablename__ = "debts"
    __table_args__ = (Index("idx_debts_user_active", "user_id", "is_active"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(160), nullable=False)
    principal_amount: Mapped[float] = mapped_column(Float, nullable=False)
    annual_rate: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    term_months: Mapped[int] = mapped_column(Integer, nullable=False)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    payment_day: Mapped[int] = mapped_column(Integer, nullable=False)
    monthly_payment: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    current_balance: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    user: Mapped[User] = relationship(back_populates="debts")
    payments: Mapped[list[DebtPayment]] = relationship(back_populates="debt")


class DebtPayment(Base, TimestampMixin):
    __tablename__ = "debt_payments"
    __table_args__ = (Index("idx_debt_payments_debt_date", "debt_id", "payment_date"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    debt_id: Mapped[int] = mapped_column(ForeignKey("debts.id", ondelete="CASCADE"), nullable=False)
    payment_date: Mapped[date] = mapped_column(Date, nullable=False)
    total_amount: Mapped[float] = mapped_column(Float, nullable=False)
    interest_amount: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    capital_amount: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text)

    debt: Mapped[Debt] = relationship(back_populates="payments")


class PersonalDebt(Base, TimestampMixin, UpdatedAtMixin):
    __tablename__ = "personal_debts"
    __table_args__ = (Index("idx_personal_debts_user_paid", "user_id", "is_paid"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    person: Mapped[str] = mapped_column(String(160), nullable=False)
    total_amount: Mapped[float] = mapped_column(Float, nullable=False)
    current_balance: Mapped[float] = mapped_column(Float, nullable=False)
    description: Mapped[str | None] = mapped_column(String(255))
    date: Mapped[date] = mapped_column(Date, nullable=False)
    is_paid: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    paid_date: Mapped[date | None] = mapped_column(Date)

    user: Mapped[User] = relationship(back_populates="personal_debts")
    payments: Mapped[list[PersonalDebtPayment]] = relationship(back_populates="personal_debt")


class PersonalDebtPayment(Base, TimestampMixin):
    __tablename__ = "personal_debt_payments"
    __table_args__ = (
        Index("idx_personal_debt_payments_debt_date", "personal_debt_id", "payment_date"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    personal_debt_id: Mapped[int] = mapped_column(
        ForeignKey("personal_debts.id", ondelete="CASCADE"), nullable=False
    )
    payment_date: Mapped[date] = mapped_column(Date, nullable=False)
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text)

    personal_debt: Mapped[PersonalDebt] = relationship(back_populates="payments")


class UserSalary(Base):
    __tablename__ = "user_salary"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, unique=True)
    amount: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now(), nullable=False
    )

    user: Mapped[User] = relationship(back_populates="salary")


class SalaryOverride(Base):
    __tablename__ = "salary_overrides"
    __table_args__ = (
        UniqueConstraint("user_id", "year", "month", "cycle", name="uq_salary_override_period"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    year: Mapped[int] = mapped_column(Integer, nullable=False)
    month: Mapped[int] = mapped_column(Integer, nullable=False)
    cycle: Mapped[int] = mapped_column(Integer, nullable=False)
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now(), nullable=False
    )

    user: Mapped[User] = relationship(back_populates="salary_overrides")


class UserPeriodMode(Base):
    __tablename__ = "user_period_mode"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, unique=True)
    mode: Mapped[str] = mapped_column(String(40), default="quincenal", nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now(), nullable=False
    )

    user: Mapped[User] = relationship(back_populates="period_mode")


class UserSetting(Base):
    __tablename__ = "user_settings"
    __table_args__ = (
        UniqueConstraint("user_id", "setting_key", name="uq_user_setting_key"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    setting_key: Mapped[str] = mapped_column(String(120), nullable=False)
    setting_value: Mapped[str] = mapped_column(Text, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now(), nullable=False
    )

    user: Mapped[User] = relationship(back_populates="settings")


class CustomQuincena(Base, TimestampMixin):
    __tablename__ = "custom_quincena"
    __table_args__ = (
        UniqueConstraint("user_id", "year", "month", "cycle", name="uq_custom_quincena_period"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    year: Mapped[int] = mapped_column(Integer, nullable=False)
    month: Mapped[int] = mapped_column(Integer, nullable=False)
    cycle: Mapped[int] = mapped_column(Integer, nullable=False)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)

    user: Mapped[User] = relationship(back_populates="custom_quincenas")


class Subscription(Base, TimestampMixin):
    __tablename__ = "subscriptions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    plan: Mapped[str] = mapped_column(String(40), default="free", nullable=False)
    stripe_customer_id: Mapped[str | None] = mapped_column(String(255))
    stripe_subscription_id: Mapped[str | None] = mapped_column(String(255))
    status: Mapped[str] = mapped_column(String(40), default="trialing", nullable=False)
    trial_end: Mapped[datetime | None] = mapped_column(DateTime)
    current_period_end: Mapped[datetime | None] = mapped_column(DateTime)

    user: Mapped[User] = relationship(back_populates="subscriptions")


class SessionToken(Base, TimestampMixin):
    __tablename__ = "sessions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    token_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    ip_address: Mapped[str | None] = mapped_column(String(64))

    user: Mapped[User] = relationship(back_populates="sessions")


Index("idx_expenses_date", Expense.date)
Index("idx_expenses_user_cycle", Expense.user_id, Expense.quincenal_cycle)


