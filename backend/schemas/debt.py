from __future__ import annotations

from datetime import date as date_cls

from pydantic import BaseModel, ConfigDict, Field


class DebtCreate(BaseModel):
    name: str = Field(min_length=1, max_length=160)
    principal_amount: float = Field(gt=0)
    annual_rate: float = Field(ge=0)
    term_months: int = Field(gt=0, le=600)
    start_date: date_cls
    payment_day: int = Field(ge=1, le=31)


class DebtUpdate(DebtCreate):
    pass


class DebtPaymentCreate(BaseModel):
    payment_date: date_cls
    total_amount: float = Field(gt=0)
    interest_amount: float = Field(ge=0)
    capital_amount: float = Field(gt=0)
    notes: str | None = None


class DebtPaymentRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    debt_id: int
    payment_date: date_cls
    total_amount: float
    interest_amount: float
    capital_amount: float
    notes: str | None = None


class DebtRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    name: str
    principal_amount: float
    annual_rate: float
    term_months: int
    start_date: date_cls
    payment_day: int
    monthly_payment: float
    current_balance: float
    is_active: bool


class DebtSummary(BaseModel):
    count: int
    total_balance: float
    monthly_payment_total: float


class DebtListResponse(BaseModel):
    items: list[DebtRead]
    summary: DebtSummary


class PersonalDebtCreate(BaseModel):
    person: str = Field(min_length=1, max_length=160)
    total_amount: float = Field(gt=0)
    description: str | None = Field(default=None, max_length=255)
    date: date_cls


class PersonalDebtUpdate(PersonalDebtCreate):
    pass


class PersonalDebtPaymentCreate(BaseModel):
    payment_date: date_cls
    amount: float = Field(gt=0)
    notes: str | None = None


class PersonalDebtPaymentRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    personal_debt_id: int
    payment_date: date_cls
    amount: float
    notes: str | None = None


class PersonalDebtRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    person: str
    total_amount: float
    current_balance: float
    description: str | None = None
    date: date_cls
    is_paid: bool
    paid_date: date_cls | None = None


class PersonalDebtSummary(BaseModel):
    count: int
    total_balance: float


class PersonalDebtListResponse(BaseModel):
    items: list[PersonalDebtRead]
    summary: PersonalDebtSummary
