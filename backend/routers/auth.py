from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Request, Response, status

from backend.config import settings
from backend.middleware import get_auth_use_cases, get_current_user, oauth2_scheme
from backend.middleware.rate_limit import rate_limit_dependency
from backend.schemas.auth import (
    AuthConfigRead,
    AuthToken,
    GoogleLoginRequest,
    LoginRequest,
    PinLoginRequest,
    PinUpdateRequest,
    ProfileRead,
    ProfileUpdateRequest,
    RefreshTokenRequest,
    RegisterOtpRequest,
    RegisterOtpResponse,
    RegisterOtpVerifyRequest,
    RegisterRequest,
    UserRead,
)
from backend.services.auth_service import AuthError

router = APIRouter(prefix='/auth', tags=['auth'])

register_rate_limit = rate_limit_dependency('auth:register', limit=30, window_seconds=60)
login_rate_limit = rate_limit_dependency('auth:login', limit=60, window_seconds=60)
pin_rate_limit = rate_limit_dependency('auth:pin', limit=60, window_seconds=60)
otp_rate_limit = rate_limit_dependency('auth:otp', limit=20, window_seconds=60)
refresh_rate_limit = rate_limit_dependency('auth:refresh', limit=120, window_seconds=60)


def to_user_read(user) -> UserRead:
    return UserRead(
        id=user.id,
        username=user.username,
        email=user.email,
        pin_enabled=bool(getattr(user, 'pin_hash', None) or getattr(user, 'pin_enabled', False)),
    )


def to_auth_response(result) -> AuthToken:
    return AuthToken(
        access_token=result.access_token,
        token_type=getattr(result, 'token_type', 'bearer'),
        expires_at=result.expires_at.isoformat(),
        refresh_token=getattr(result, 'refresh_token', None),
        refresh_expires_at=(
            result.refresh_expires_at.isoformat()
            if getattr(result, 'refresh_expires_at', None) is not None
            else None
        ),
        user=to_user_read(result.user),
    )


@router.get('/config', response_model=AuthConfigRead)
async def auth_config() -> AuthConfigRead:
    return AuthConfigRead(
        google_enabled=settings.google_enabled,
        google_client_id=settings.google_client_id,
    )


@router.post('/register', response_model=AuthToken, status_code=status.HTTP_201_CREATED, dependencies=[Depends(register_rate_limit)])
async def register(payload: RegisterRequest, request: Request, auth_uc=Depends(get_auth_use_cases)):
    try:
        result = await auth_uc.register(
            payload.username,
            payload.email,
            payload.password,
            pin=payload.pin,
            ip_address=request.client.host if request.client else None,
        )
    except AuthError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc
    return to_auth_response(result)


@router.post('/register/request-otp', response_model=RegisterOtpResponse, dependencies=[Depends(otp_rate_limit)])
async def request_register_otp(payload: RegisterOtpRequest, auth_uc=Depends(get_auth_use_cases)):
    try:
        result = await auth_uc.request_registration_otp(payload.username, payload.email, payload.password)
    except AuthError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc
    return RegisterOtpResponse(
        message=result.message,
        email=result.email,
        expires_in_seconds=result.expires_in_seconds,
        development_code=result.development_code,
    )


@router.post('/register/verify-otp', response_model=AuthToken, dependencies=[Depends(otp_rate_limit)])
async def verify_register_otp(payload: RegisterOtpVerifyRequest, request: Request, auth_uc=Depends(get_auth_use_cases)):
    try:
        result = await auth_uc.verify_registration_otp(
            payload.email,
            payload.code,
            ip_address=request.client.host if request.client else None,
        )
    except AuthError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc
    return to_auth_response(result)


@router.post('/login', response_model=AuthToken, dependencies=[Depends(login_rate_limit)])
async def login(payload: LoginRequest, request: Request, auth_uc=Depends(get_auth_use_cases)):
    try:
        result = await auth_uc.login(
            payload.identifier,
            payload.password,
            ip_address=request.client.host if request.client else None,
        )
    except AuthError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc
    return to_auth_response(result)


@router.post('/refresh', response_model=AuthToken, dependencies=[Depends(refresh_rate_limit)])
async def refresh_token(payload: RefreshTokenRequest, request: Request, auth_uc=Depends(get_auth_use_cases)):
    try:
        result = await auth_uc.refresh(
            payload.refresh_token,
            ip_address=request.client.host if request.client else None,
        )
    except AuthError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc
    return to_auth_response(result)


@router.post('/google', response_model=AuthToken, dependencies=[Depends(login_rate_limit)])
async def google_login(payload: GoogleLoginRequest, request: Request, auth_uc=Depends(get_auth_use_cases)):
    try:
        result = await auth_uc.login_with_google(
            payload.id_token,
            ip_address=request.client.host if request.client else None,
        )
    except AuthError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc
    return to_auth_response(result)


@router.post('/pin', response_model=AuthToken, dependencies=[Depends(pin_rate_limit)])
async def pin_login(payload: PinLoginRequest, request: Request, auth_uc=Depends(get_auth_use_cases)):
    try:
        result = await auth_uc.login_with_pin(
            payload.identifier,
            payload.pin,
            ip_address=request.client.host if request.client else None,
        )
    except AuthError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc
    return to_auth_response(result)


@router.post('/logout', status_code=status.HTTP_204_NO_CONTENT)
async def logout(token: str = Depends(oauth2_scheme), auth_uc=Depends(get_auth_use_cases)):
    try:
        await auth_uc.logout(token)
    except AuthError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get('/me', response_model=UserRead)
async def me(current_user=Depends(get_current_user)):
    return to_user_read(current_user)


@router.get('/profiles', response_model=list[ProfileRead])
async def list_profiles(current_user=Depends(get_current_user), auth_uc=Depends(get_auth_use_cases)):
    try:
        profiles = await auth_uc.list_profiles(current_user.id)
    except AuthError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc
    return [to_user_read(profile) for profile in profiles]


@router.patch('/me', response_model=UserRead)
async def update_me(payload: ProfileUpdateRequest, current_user=Depends(get_current_user), auth_uc=Depends(get_auth_use_cases)):
    try:
        user = await auth_uc.update_profile(current_user.id, username=payload.username, email=payload.email)
    except AuthError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc
    return to_user_read(user)


@router.put('/me/pin', response_model=UserRead)
async def update_my_pin(payload: PinUpdateRequest, current_user=Depends(get_current_user), auth_uc=Depends(get_auth_use_cases)):
    try:
        user = await auth_uc.update_pin(current_user.id, pin=payload.pin)
    except AuthError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc
    return to_user_read(user)


@router.delete('/me', status_code=status.HTTP_204_NO_CONTENT)
async def deactivate_me(current_user=Depends(get_current_user), auth_uc=Depends(get_auth_use_cases)):
    try:
        await auth_uc.deactivate_profile(current_user.id)
    except AuthError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc
    return Response(status_code=status.HTTP_204_NO_CONTENT)
