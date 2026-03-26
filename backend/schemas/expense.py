from __future__ import annotations

from datetime import date as date_cls

from pydantic import BaseModel, Field


class ExpenseCreate(BaseModel):
    amount: float = Field(gt=0)
    description: str = Field(min_length=1, max_length=255)
    date: date_cls
    category_id: int = Field(gt=0)
    source: str = Field(default="sueldo")


class ExpenseUpdate(BaseModel):
    amount: float | None = Field(default=None, gt=0)
    description: str | None = Field(default=None, min_length=1, max_length=255)
    date: date_cls | None = None
    category_id: int | None = Field(default=None, gt=0)
    source: str | None = None


class ExpenseRead(BaseModel):
    id: int
    amount: float
    description: str
    date: date_cls
    quincenal_cycle: int
    status: str
    category_ids: list[int]
