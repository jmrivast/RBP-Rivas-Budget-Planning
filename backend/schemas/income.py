from __future__ import annotations

from datetime import date as date_cls

from pydantic import BaseModel, ConfigDict, Field


class IncomeCreate(BaseModel):
    amount: float = Field(gt=0)
    description: str = Field(min_length=1, max_length=255)
    date: date_cls


class IncomeUpdate(BaseModel):
    amount: float | None = Field(default=None, gt=0)
    description: str | None = Field(default=None, min_length=1, max_length=255)
    date: date_cls | None = None


class IncomeRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    amount: float
    description: str
    date: date_cls
    income_type: str


class SalaryUpdateRequest(BaseModel):
    amount: float = Field(ge=0)


class SalaryOverrideRequest(BaseModel):
    year: int = Field(ge=2000, le=9999)
    month: int = Field(ge=1, le=12)
    cycle: int = Field(ge=1, le=2)
    amount: float | None = Field(default=None, ge=0)


class SalaryResponse(BaseModel):
    base: float
    override: float | None = None
    effective: float


SalaryUpdate = SalaryUpdateRequest
SalaryRead = SalaryResponse
SalaryOverrideDelete = SalaryOverrideRequest
