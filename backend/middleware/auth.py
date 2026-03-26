from __future__ import annotations

from fastapi import Depends, HTTPException, Request
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.infrastructure import BackupUseCases, Container, ExportUseCases, FinanceUseCases, SubscriptionUseCases, build_container
from backend.database import get_db
from backend.services.auth_service import AuthError


oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


def get_container(session: AsyncSession = Depends(get_db)) -> Container:
    return build_container(session)


def get_auth_use_cases(container: Container = Depends(get_container)):
    return container.auth_use_cases()


async def get_current_user(
    request: Request,
    token: str = Depends(oauth2_scheme),
    auth_uc=Depends(get_auth_use_cases),
):
    try:
        user = await auth_uc.me(token)
    except AuthError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc
    request.state.user = user
    return user


def get_finance_use_cases(
    current_user=Depends(get_current_user),
    container: Container = Depends(get_container),
) -> FinanceUseCases:
    return container.finance_use_cases(current_user.id)


def get_export_use_cases(
    current_user=Depends(get_current_user),
    container: Container = Depends(get_container),
) -> ExportUseCases:
    return container.export_use_cases(current_user.id)


def get_backup_use_cases(container: Container = Depends(get_container)) -> BackupUseCases:
    return container.backup_use_cases()


def get_subscription_use_cases(container: Container = Depends(get_container)) -> SubscriptionUseCases:
    return container.subscription_use_cases()
