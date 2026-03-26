from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field


class SavingsActionRequest(BaseModel):
    amount: float = Field(gt=0)


class SavingsSummary(BaseModel):
    total: float
    period_savings: float


class WithdrawResponse(BaseModel):
    ok: bool
    total: float


class SavingsGoalCreate(BaseModel):
    name: str = Field(min_length=1, max_length=160)
    target_amount: float = Field(gt=0)


class SavingsGoalUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=160)
    target_amount: float | None = Field(default=None, gt=0)


class SavingsGoalRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    name: str
    target_amount: float


AmountRequest = SavingsActionRequest
SavingsRead = SavingsSummary
