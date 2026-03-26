from __future__ import annotations

from datetime import date as date_cls

from pydantic import BaseModel, Field


class SettingsUpdate(BaseModel):
    period_mode: str | None = None
    pay_day_1: int | None = Field(default=None, ge=1, le=31)
    pay_day_2: int | None = Field(default=None, ge=1, le=31)
    monthly_pay_day: int | None = Field(default=None, ge=1, le=31)
    theme: str | None = None
    auto_export: bool | None = None
    include_beta: bool | None = None


class SettingsResponse(BaseModel):
    period_mode: str
    pay_day_1: int
    pay_day_2: int
    monthly_pay_day: int
    theme: str
    auto_export: bool
    include_beta: bool


class CustomQuincenaRequest(BaseModel):
    year: int = Field(ge=2000, le=9999)
    month: int = Field(ge=1, le=12)
    cycle: int = Field(ge=1, le=2)
    start_date: date_cls
    end_date: date_cls


class CustomQuincenaResponse(BaseModel):
    year: int
    month: int
    cycle: int
    start_date: date_cls
    end_date: date_cls


SettingsRead = SettingsResponse
CustomQuincenaRead = CustomQuincenaResponse
CustomQuincenaUpdate = CustomQuincenaRequest
