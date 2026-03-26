from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from backend.database.models import User


class UserRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def create(
        self,
        username: str,
        *,
        email: str | None = None,
        password_hash: str | None = None,
        pin_hash: str | None = None,
        pin_length: int = 0,
    ) -> User:
        user = User(
            username=username,
            email=email,
            password_hash=password_hash,
            pin_hash=pin_hash,
            pin_length=pin_length,
            is_active=True,
        )
        self.session.add(user)
        await self.session.flush()
        return user

    async def get_by_id(self, user_id: int) -> User | None:
        return await self.session.get(User, user_id)

    async def get_by_username(self, username: str) -> User | None:
        statement = select(User).where(User.username == username)
        return (await self.session.scalars(statement)).first()

    async def get_by_email(self, email: str) -> User | None:
        statement = select(User).where(User.email == email)
        return (await self.session.scalars(statement)).first()

    async def list_active(self) -> list[User]:
        statement = select(User).where(User.is_active.is_(True)).order_by(User.id)
        return list((await self.session.scalars(statement)).all())

    async def update_profile(
        self,
        user_id: int,
        *,
        username: str | None = None,
        email: str | None = None,
        update_email: bool = False,
    ) -> User | None:
        user = await self.get_by_id(user_id)
        if user is None:
            return None
        if username is not None:
            user.username = username
        if update_email:
            user.email = email
        await self.session.flush()
        return user

    async def set_pin(self, user_id: int, *, pin_hash: str | None, pin_length: int) -> User | None:
        user = await self.get_by_id(user_id)
        if user is None:
            return None
        user.pin_hash = pin_hash
        user.pin_length = pin_length
        await self.session.flush()
        return user

    async def deactivate(self, user_id: int) -> bool:
        user = await self.get_by_id(user_id)
        if user is None:
            return False
        user.is_active = False
        await self.session.flush()
        return True
