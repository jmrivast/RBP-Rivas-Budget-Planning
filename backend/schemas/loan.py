from __future__ import annotations

from datetime import date as date_cls

from pydantic import BaseModel, ConfigDict, Field


class LoanCreate(BaseModel):
    person: str = Field(min_length=1, max_length=160)
    amount: float = Field(gt=0)
    description: str | None = Field(default=None, max_length=255)
    date: date_cls
    deduction_type: str = 'ninguno'


class LoanUpdate(BaseModel):
    person: str | None = Field(default=None, min_length=1, max_length=160)
    amount: float | None = Field(default=None, gt=0)
    description: str | None = Field(default=None, max_length=255)
    date: date_cls | None = None
    deduction_type: str | None = None


class LoanRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    person: str
    amount: float
    description: str | None = None
    date: date_cls
    is_paid: bool
    paid_date: date_cls | None = None
    deduction_type: str


class LoanPayResponse(BaseModel):
    ok: bool = True
    loan: LoanRead
