from __future__ import annotations

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    username: str
    email: EmailStr | None = None
    pin_enabled: bool = False


class RegisterRequest(BaseModel):
    username: str = Field(min_length=1, max_length=120)
    email: EmailStr | None = None
    password: str = Field(min_length=6)
    pin: str | None = None

    @field_validator('pin')
    @classmethod
    def validate_pin(cls, value: str | None) -> str | None:
        if value is None:
            return value
        if len(value) not in {4, 6} or not value.isdigit():
            raise ValueError('El PIN debe tener 4 o 6 digitos.')
        return value


class RegisterOtpRequest(BaseModel):
    username: str = Field(min_length=1, max_length=120)
    email: EmailStr
    password: str = Field(min_length=6)


class RegisterOtpVerifyRequest(BaseModel):
    email: EmailStr
    code: str = Field(min_length=6, max_length=6)


class RegisterOtpResponse(BaseModel):
    message: str
    email: EmailStr
    expires_in_seconds: int = 600
    development_code: str | None = None


class GoogleLoginRequest(BaseModel):
    id_token: str = Field(min_length=1)


class AuthConfigRead(BaseModel):
    google_enabled: bool = False
    google_client_id: str = ''


class LoginRequest(BaseModel):
    identifier: str = Field(min_length=1)
    password: str = Field(min_length=1)


class RefreshTokenRequest(BaseModel):
    refresh_token: str = Field(min_length=1)


class PinLoginRequest(BaseModel):
    identifier: str = Field(min_length=1)
    pin: str = Field(min_length=4, max_length=6)


class ProfileUpdateRequest(BaseModel):
    username: str = Field(min_length=1, max_length=120)
    email: EmailStr | None = None


class PinUpdateRequest(BaseModel):
    pin: str | None = None

    @field_validator('pin')
    @classmethod
    def validate_pin(cls, value: str | None) -> str | None:
        if value is None:
            return None
        normalized = value.strip()
        if not normalized:
            return None
        if len(normalized) not in {4, 6} or not normalized.isdigit():
            raise ValueError('El PIN debe tener 4 o 6 digitos.')
        return normalized


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = 'bearer'
    expires_at: str
    refresh_token: str | None = None
    refresh_expires_at: str | None = None
    user: UserRead


ProfileRead = UserRead
AuthResponse = TokenResponse
AuthToken = TokenResponse
