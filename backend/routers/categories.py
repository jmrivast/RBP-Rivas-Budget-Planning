from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status

from backend.middleware import get_finance_use_cases
from backend.schemas.category import CategoryCreate, CategoryRead, CategoryUpdate
from backend.services.finance_service import FinanceError

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryRead])
async def list_categories(uc=Depends(get_finance_use_cases)):
    return [CategoryRead.model_validate(item) for item in await uc.categories.list()]


@router.post("", response_model=CategoryRead, status_code=status.HTTP_201_CREATED)
async def create_category(payload: CategoryCreate, uc=Depends(get_finance_use_cases)):
    try:
        category = await uc.categories.create(payload.name)
    except FinanceError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    return CategoryRead.model_validate(category)


@router.put("/{category_id}", response_model=CategoryRead)
async def update_category(category_id: int, payload: CategoryUpdate, uc=Depends(get_finance_use_cases)):
    try:
        category = await uc.categories.rename(category_id, payload.name or "")
    except FinanceError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    return CategoryRead.model_validate(category)


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_category(category_id: int, uc=Depends(get_finance_use_cases)):
    try:
        await uc.categories.delete(category_id)
    except FinanceError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
