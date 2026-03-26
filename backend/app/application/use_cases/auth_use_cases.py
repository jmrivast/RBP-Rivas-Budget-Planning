from __future__ import annotations

from dataclasses import dataclass

from backend.app.domain.entities import AuthToken, User
from backend.app.domain.ports import AuthPort


@dataclass(slots=True)
class AuthUseCases:
    auth: AuthPort

    async def register(self, username: str, email: str | None, password: str, *, pin: str | None = None, ip_address: str | None = None) -> AuthToken:
        return await self.auth.register(username, email, password, pin=pin, ip_address=ip_address)

    async def request_registration_otp(self, username: str, email: str, password: str):
        return await self.auth.request_registration_otp(username, email, password)

    async def verify_registration_otp(self, email: str, code: str, *, ip_address: str | None = None) -> AuthToken:
        return await self.auth.verify_registration_otp(email, code, ip_address=ip_address)

    async def login(self, identifier: str, password: str, *, ip_address: str | None = None) -> AuthToken:
        return await self.auth.login(identifier, password, ip_address=ip_address)

    async def refresh(self, refresh_token: str, *, ip_address: str | None = None) -> AuthToken:
        return await self.auth.refresh(refresh_token, ip_address=ip_address)

    async def login_with_pin(self, identifier: str, pin: str, *, ip_address: str | None = None) -> AuthToken:
        return await self.auth.login_with_pin(identifier, pin, ip_address=ip_address)

    async def login_with_google(self, id_token: str, *, ip_address: str | None = None) -> AuthToken:
        return await self.auth.login_with_google(id_token, ip_address=ip_address)

    async def list_profiles(self, user_id: int | None = None) -> list[User]:
        return await self.auth.list_profiles(user_id)

    async def update_profile(self, user_id: int, *, username: str | None = None, email: str | None = None) -> User:
        return await self.auth.update_profile(user_id, username=username, email=email)

    async def update_pin(self, user_id: int, *, pin: str | None) -> User:
        return await self.auth.update_pin(user_id, pin=pin)

    async def deactivate_profile(self, user_id: int) -> None:
        await self.auth.deactivate_profile(user_id)

    async def logout(self, token: str) -> None:
        await self.auth.logout(token)

    async def me(self, token: str) -> User:
        return await self.auth.get_current_user_from_token(token)
