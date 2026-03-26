from __future__ import annotations

from backend.app.domain.entities import AuthToken, User
from backend.app.domain.ports import AuthPort
from backend.app.infrastructure.adapters.mappers import to_auth_token, to_user
from backend.services.auth_service import AuthService


class AuthServiceAdapter(AuthPort):
    def __init__(self, service: AuthService) -> None:
        self._service = service

    async def register(self, username: str, email: str | None, password: str, *, pin: str | None = None, ip_address: str | None = None) -> AuthToken:
        result = await self._service.register(username, email, password, pin=pin, ip_address=ip_address)
        return to_auth_token(result)

    async def request_registration_otp(self, username: str, email: str, password: str):
        return await self._service.request_registration_otp(username, email, password)

    async def verify_registration_otp(self, email: str, code: str, *, ip_address: str | None = None) -> AuthToken:
        result = await self._service.verify_registration_otp(email, code, ip_address=ip_address)
        return to_auth_token(result)

    async def login(self, identifier: str, password: str, *, ip_address: str | None = None) -> AuthToken:
        result = await self._service.login(identifier, password, ip_address=ip_address)
        return to_auth_token(result)

    async def refresh(self, refresh_token: str, *, ip_address: str | None = None) -> AuthToken:
        result = await self._service.refresh(refresh_token, ip_address=ip_address)
        return to_auth_token(result)

    async def login_with_pin(self, identifier: str, pin: str, *, ip_address: str | None = None) -> AuthToken:
        result = await self._service.login_with_pin(identifier, pin, ip_address=ip_address)
        return to_auth_token(result)

    async def login_with_google(self, id_token: str, *, ip_address: str | None = None) -> AuthToken:
        result = await self._service.login_with_google(id_token, ip_address=ip_address)
        return to_auth_token(result)

    async def list_profiles(self, user_id: int | None = None) -> list[User]:
        return [to_user(item) for item in await self._service.list_profiles(user_id)]

    async def update_profile(self, user_id: int, *, username: str | None = None, email: str | None = None) -> User:
        model = await self._service.update_profile(user_id, username=username, email=email)
        return to_user(model)

    async def update_pin(self, user_id: int, *, pin: str | None) -> User:
        model = await self._service.update_pin(user_id, pin=pin)
        return to_user(model)

    async def deactivate_profile(self, user_id: int) -> None:
        await self._service.deactivate_profile(user_id)

    async def logout(self, token: str) -> None:
        await self._service.logout(token)

    async def get_current_user_from_token(self, token: str) -> User:
        model = await self._service.get_current_user_from_token(token)
        return to_user(model)
