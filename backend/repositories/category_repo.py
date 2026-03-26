from __future__ import annotations

from sqlalchemy import update, select
from sqlalchemy.ext.asyncio import AsyncSession

from backend.database.models import Category


class CategoryRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def create(
        self,
        user_id: int,
        name: str,
        *,
        color: str | None = None,
        icon: str | None = None,
    ) -> Category:
        category = Category(user_id=user_id, name=name, color=color, icon=icon)
        self.session.add(category)
        await self.session.flush()
        return category

    async def list_by_user(self, user_id: int) -> list[Category]:
        statement = select(Category).where(Category.user_id == user_id).order_by(Category.name)
        return list((await self.session.scalars(statement)).all())

    async def get_by_name(self, user_id: int, name: str) -> Category | None:
        statement = select(Category).where(
            Category.user_id == user_id,
            Category.name == name,
        )
        return (await self.session.scalars(statement)).first()

    async def get_by_id(self, category_id: int) -> Category | None:
        return await self.session.get(Category, category_id)

    async def update(self, category_id: int, **values: object) -> Category | None:
        values = {key: value for key, value in values.items() if value is not None}
        if values:
            await self.session.execute(
                update(Category).where(Category.id == category_id).values(**values)
            )
            await self.session.flush()
        return await self.get_by_id(category_id)

    async def delete(self, category_id: int) -> None:
        category = await self.get_by_id(category_id)
        if category is not None:
            await self.session.delete(category)
            await self.session.flush()
