from __future__ import annotations

from dataclasses import dataclass

from backend.app.domain.entities import Category
from backend.app.domain.ports import FinancePort


@dataclass(slots=True)
class CategoriesUseCases:
    finance: FinancePort

    async def list(self) -> list[Category]:
        return await self.finance.get_categories()

    async def create(self, name: str) -> Category:
        return await self.finance.add_category(name)

    async def rename(self, category_id: int, new_name: str) -> Category:
        return await self.finance.rename_category(category_id, new_name)

    async def delete(self, category_id: int) -> None:
        await self.finance.delete_category(category_id)
