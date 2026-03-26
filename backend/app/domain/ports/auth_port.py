from __future__ import annotations

from typing import Protocol

from backend.app.domain.entities import AuthToken, User


class AuthPort(Protocol):
    async def register(
        self,
        username: str,
        email: str | None,
        password: str,
        *,
        pin: str | None = None,
        ip_address: str | None = None,
    ) -> AuthToken: ...

    async def request_registration_otp(self, username: str, email: str, password: str): ...
    async def verify_registration_otp(self, email: str, code: str, *, ip_address: str | None = None) -> AuthToken: ...
    async def login_with_google(self, id_token: str, *, ip_address: str | None = None) -> AuthToken: ...

    async def login(
        self,
        identifier: str,
        password: str,
        *,
        ip_address: str | None = None,
    ) -> AuthToken: ...

    async def refresh(
        self,
        refresh_token: str,
        *,
        ip_address: str | None = None,
    ) -> AuthToken: ...

    async def login_with_pin(
        self,
        identifier: str,
        pin: str,
        *,
        ip_address: str | None = None,
    ) -> AuthToken: ...

    async def list_profiles(self, user_id: int | None = None) -> list[User]: ...
    async def update_profile(self, user_id: int, *, username: str | None = None, email: str | None = None) -> User: ...
    async def update_pin(self, user_id: int, *, pin: str | None) -> User: ...
    async def deactivate_profile(self, user_id: int) -> None: ...
    async def logout(self, token: str) -> None: ...
    async def get_current_user_from_token(self, token: str) -> User: ...
