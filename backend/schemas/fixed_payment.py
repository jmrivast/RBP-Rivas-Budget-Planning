from __future__ import annotations

from pydantic import BaseModel, Field


class FixedPaymentCreate(BaseModel):
    name: str = Field(min_length=1, max_length=160)
    amount: float = Field(gt=0)
    due_day: int = Field(ge=0, le=31)
    category_id: int | None = Field(default=None, gt=0)
    no_fixed_date: bool = False


class FixedPaymentUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=160)
    amount: float | None = Field(default=None, gt=0)
    due_day: int | None = Field(default=None, ge=0, le=31)
    category_id: int | None = Field(default=None, gt=0)
    no_fixed_date: bool = False


class FixedPaymentToggleRequest(BaseModel):
    paid: bool
    year: int = Field(ge=2000, le=9999)
    month: int = Field(ge=1, le=12)
    cycle: int = Field(ge=1, le=2)


class FixedPaymentRead(BaseModel):
    id: int
    name: str
    amount: float
    due_day: int
    category_id: int | None = None
    is_paid: bool = False
    is_overdue: bool = False
    due_date: str = ""


FixedPaymentStatusRead = FixedPaymentRead
FixedPaymentToggle = FixedPaymentToggleRequest
