from __future__ import annotations

import hashlib
import secrets
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

import bcrypt
import httpx
from jose import JWTError, jwt
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from backend.config import get_settings
from backend.database.models import OtpChallenge, SessionToken, User
from backend.repositories.category_repo import CategoryRepository
from backend.repositories.settings_repo import SettingsRepository
from backend.repositories.subscription_repo import SubscriptionRepository
from backend.repositories.user_repo import UserRepository

DEFAULT_CATEGORIES = [
    'Comida',
    'Combustible',
    'Uber/Taxi',
    'Subscripciones',
    'Varios/Snacks',
    'Otros',
]

settings = get_settings()


class AuthError(Exception):
    def __init__(self, message: str, *, status_code: int = 400) -> None:
        super().__init__(message)
        self.message = message
        self.status_code = status_code


@dataclass(slots=True)
class AuthResult:
    user: User
    access_token: str
    expires_at: datetime
    token_type: str = 'bearer'
    refresh_token: str | None = None
    refresh_expires_at: datetime | None = None


@dataclass(slots=True)
class OtpRequestResult:
    email: str
    message: str
    expires_in_seconds: int = 600
    development_code: str | None = None


class AuthService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session
        self.user_repo = UserRepository(session)
        self.category_repo = CategoryRepository(session)
        self.settings_repo = SettingsRepository(session)
        self.subscription_repo = SubscriptionRepository(session)

    async def _ensure_auth_support_tables(self) -> None:
        await self.session.run_sync(
            lambda sync_session: OtpChallenge.__table__.create(bind=sync_session.connection(), checkfirst=True)
        )

    @staticmethod
    def _hash_pin(pin: str) -> str:
        return bcrypt.hashpw(pin.strip().encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

    @staticmethod
    def _hash_text(value: str) -> str:
        return hashlib.sha256(value.strip().encode('utf-8')).hexdigest()

    @staticmethod
    def _legacy_hash_pin(pin: str) -> str:
        return hashlib.sha256(pin.strip().encode('utf-8')).hexdigest()

    @staticmethod
    def _is_bcrypt_hash(pin_hash: str | None) -> bool:
        return bool(pin_hash and pin_hash.startswith(('$2a$', '$2b$', '$2y$')))

    @classmethod
    def _verify_pin(cls, pin: str, pin_hash: str | None) -> tuple[bool, bool]:
        if not pin_hash:
            return False, False
        normalized = pin.strip().encode('utf-8')
        if cls._is_bcrypt_hash(pin_hash):
            try:
                return bcrypt.checkpw(normalized, pin_hash.encode('utf-8')), False
            except ValueError:
                return False, False
        return secrets.compare_digest(cls._legacy_hash_pin(pin), pin_hash), True

    @staticmethod
    def _token_hash(token: str) -> str:
        return hashlib.sha256(token.encode('utf-8')).hexdigest()

    @staticmethod
    def hash_password(password: str) -> str:
        return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

    @staticmethod
    def verify_password(password: str, password_hash: str | None) -> bool:
        if not password_hash:
            return False
        return bcrypt.checkpw(password.encode('utf-8'), password_hash.encode('utf-8'))

    @staticmethod
    def _validate_pin(pin: str) -> int:
        value = pin.strip()
        if len(value) not in {4, 6} or not value.isdigit():
            raise AuthError('El PIN debe tener 4 o 6 digitos.')
        return len(value)

    @staticmethod
    def _normalize_email(email: str | None, *, required: bool = False) -> str | None:
        normalized = email.strip().lower() if isinstance(email, str) else None
        if required and not normalized:
            raise AuthError('El correo es obligatorio.')
        return normalized or None

    async def _bootstrap_user_defaults(self, user_id: int) -> None:
        categories = await self.category_repo.list_by_user(user_id)
        if not categories:
            for name in DEFAULT_CATEGORIES:
                await self.category_repo.create(user_id, name)
        await self.settings_repo.set_period_mode(user_id, 'quincenal')
        await self.settings_repo.set_setting(user_id, 'quincenal_pay_day_1', '1')
        await self.settings_repo.set_setting(user_id, 'quincenal_pay_day_2', '16')
        await self.settings_repo.set_setting(user_id, 'monthly_pay_day', '1')
        await self.settings_repo.set_setting(user_id, 'theme_preset', 'classic_flet')
        await self.settings_repo.set_setting(user_id, 'auto_export_close_period', 'false')
        await self.settings_repo.set_setting(user_id, 'include_beta_updates', 'false')
        await self.subscription_repo.ensure_default(user_id)

    def _build_token(self, user: User, *, expires_at: datetime, kind: str) -> str:
        payload = {
            'sub': str(user.id),
            'exp': expires_at,
            'username': user.username,
            'jti': secrets.token_urlsafe(8),
            'kind': kind,
        }
        return jwt.encode(payload, settings.secret_key, algorithm=settings.jwt_algorithm)

    async def _store_session_token(self, *, user_id: int, token: str, expires_at: datetime, ip_address: str | None) -> None:
        self.session.add(
            SessionToken(
                user_id=user_id,
                token_hash=self._token_hash(token),
                expires_at=expires_at,
                ip_address=ip_address,
            )
        )

    async def _issue_session_tokens(self, user: User, *, ip_address: str | None = None) -> AuthResult:
        access_expires_at = datetime.now(timezone.utc) + timedelta(minutes=settings.access_token_expire_minutes)
        refresh_expires_at = datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_expire_days)
        access_token = self._build_token(user, expires_at=access_expires_at, kind='access')
        refresh_token = self._build_token(user, expires_at=refresh_expires_at, kind='refresh')
        await self._store_session_token(
            user_id=user.id,
            token=access_token,
            expires_at=access_expires_at,
            ip_address=ip_address,
        )
        await self._store_session_token(
            user_id=user.id,
            token=refresh_token,
            expires_at=refresh_expires_at,
            ip_address=ip_address,
        )
        await self.session.commit()
        await self.session.refresh(user)
        return AuthResult(
            user=user,
            access_token=access_token,
            expires_at=access_expires_at,
            refresh_token=refresh_token,
            refresh_expires_at=refresh_expires_at,
        )

    def _decode_token_payload(self, token: str, *, expected_kind: str | None = None) -> dict:
        try:
            payload = jwt.decode(token, settings.secret_key, algorithms=[settings.jwt_algorithm])
        except JWTError as exc:
            raise AuthError('Token invalido.', status_code=401) from exc
        user_id = payload.get('sub')
        if user_id is None:
            raise AuthError('Token invalido.', status_code=401)
        token_kind = payload.get('kind', 'access')
        if expected_kind is not None and token_kind != expected_kind:
            raise AuthError('Tipo de token invalido.', status_code=401)
        return payload

    async def _ensure_unique_username(self, base_username: str) -> str:
        candidate = base_username.strip() or 'Perfil'
        if await self.user_repo.get_by_username(candidate) is None:
            return candidate
        suffix = 2
        while True:
            next_candidate = f'{candidate}-{suffix}'
            if await self.user_repo.get_by_username(next_candidate) is None:
                return next_candidate
            suffix += 1

    async def register(
        self,
        username: str,
        email: str | None,
        password: str,
        *,
        pin: str | None = None,
        ip_address: str | None = None,
    ) -> AuthResult:
        username = username.strip()
        if not username:
            raise AuthError('El nombre de usuario es obligatorio.')
        if len(password) < 6:
            raise AuthError('La contrasena debe tener al menos 6 caracteres.')
        if await self.user_repo.get_by_username(username):
            raise AuthError('Ese nombre de usuario ya existe.')
        normalized_email = self._normalize_email(email)
        if normalized_email and await self.user_repo.get_by_email(normalized_email):
            raise AuthError('Ese correo ya existe.')

        pin_hash = None
        pin_length = 0
        if pin:
            pin_length = self._validate_pin(pin)
            pin_hash = self._hash_pin(pin)

        user = await self.user_repo.create(
            username,
            email=normalized_email,
            password_hash=self.hash_password(password),
            pin_hash=pin_hash,
            pin_length=pin_length,
        )
        await self._bootstrap_user_defaults(user.id)
        return await self._issue_session_tokens(user, ip_address=ip_address)

    async def request_registration_otp(self, username: str, email: str, password: str) -> OtpRequestResult:
        await self._ensure_auth_support_tables()
        normalized_username = username.strip()
        if not normalized_username:
            raise AuthError('El nombre del perfil es obligatorio.')
        if len(password) < 6:
            raise AuthError('La contrasena debe tener al menos 6 caracteres.')
        normalized_email = self._normalize_email(email, required=True)
        if await self.user_repo.get_by_email(normalized_email):
            raise AuthError('Ese correo ya existe.')
        if await self.user_repo.get_by_username(normalized_username):
            raise AuthError('Ese nombre de usuario ya existe.')

        await self.session.execute(
            delete(OtpChallenge).where(
                OtpChallenge.email == normalized_email,
                OtpChallenge.purpose == 'register',
            )
        )

        code = f'{secrets.randbelow(1000000):06d}'
        self.session.add(
            OtpChallenge(
                email=normalized_email,
                purpose='register',
                username=normalized_username,
                password_hash=self.hash_password(password),
                code_hash=self._hash_text(code),
                expires_at=datetime.now(timezone.utc) + timedelta(minutes=10),
            )
        )
        await self.session.commit()
        return OtpRequestResult(
            email=normalized_email,
            message='OTP generado correctamente.',
            development_code=None if settings.is_production else code,
        )

    async def verify_registration_otp(
        self,
        email: str,
        code: str,
        *,
        ip_address: str | None = None,
    ) -> AuthResult:
        normalized_email = self._normalize_email(email, required=True)
        statement = (
            select(OtpChallenge)
            .where(
                OtpChallenge.email == normalized_email,
                OtpChallenge.purpose == 'register',
            )
            .order_by(OtpChallenge.id.desc())
        )
        challenge = (await self.session.scalars(statement)).first()
        if challenge is None or challenge.consumed_at is not None:
            raise AuthError('No hay un OTP activo para ese correo.', status_code=404)
        challenge_expires_at = challenge.expires_at if getattr(challenge.expires_at, 'tzinfo', None) else challenge.expires_at.replace(tzinfo=timezone.utc)
        if challenge_expires_at <= datetime.now(timezone.utc):
            raise AuthError('El OTP ya expiro.', status_code=410)
        if challenge.attempt_count >= 5:
            raise AuthError('El OTP fue bloqueado por demasiados intentos.', status_code=429)
        if not secrets.compare_digest(challenge.code_hash, self._hash_text(code)):
            challenge.attempt_count += 1
            await self.session.commit()
            raise AuthError('Codigo OTP invalido.', status_code=401)
        if await self.user_repo.get_by_email(normalized_email):
            raise AuthError('Ese correo ya existe.')

        challenge.consumed_at = datetime.now(timezone.utc)
        username = await self._ensure_unique_username(challenge.username)
        user = await self.user_repo.create(
            username,
            email=normalized_email,
            password_hash=challenge.password_hash,
            pin_hash=challenge.pin_hash,
            pin_length=challenge.pin_length,
        )
        await self._bootstrap_user_defaults(user.id)
        return await self._issue_session_tokens(user, ip_address=ip_address)

    async def _verify_google_token(self, id_token: str) -> dict:
        if not settings.google_enabled:
            raise AuthError('Google Sign-In no esta configurado.', status_code=503)
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                response = await client.get(
                    'https://oauth2.googleapis.com/tokeninfo',
                    params={'id_token': id_token},
                )
        except httpx.HTTPError as exc:
            raise AuthError('No se pudo verificar el token de Google.', status_code=502) from exc

        if response.status_code != 200:
            raise AuthError('Token de Google invalido.', status_code=401)
        payload = response.json()
        audience = str(payload.get('aud', ''))
        if settings.google_client_id and audience != settings.google_client_id:
            raise AuthError('Token de Google invalido para esta app.', status_code=401)
        if str(payload.get('email_verified', '')).lower() != 'true':
            raise AuthError('La cuenta de Google debe tener email verificado.', status_code=401)
        email = self._normalize_email(payload.get('email'), required=True)
        name = str(payload.get('name') or email.split('@', 1)[0]).strip() or 'Perfil'
        return {'email': email, 'name': name}

    async def login_with_google(self, id_token: str, *, ip_address: str | None = None) -> AuthResult:
        profile = await self._verify_google_token(id_token)
        user = await self.user_repo.get_by_email(profile['email'])
        if user is None:
            username = await self._ensure_unique_username(profile['name'])
            user = await self.user_repo.create(username, email=profile['email'])
            await self._bootstrap_user_defaults(user.id)
        elif not user.is_active:
            raise AuthError('Usuario no disponible.', status_code=401)
        return await self._issue_session_tokens(user, ip_address=ip_address)

    async def login(self, identifier: str, password: str, *, ip_address: str | None = None) -> AuthResult:
        identifier = identifier.strip()
        user = await self.user_repo.get_by_email(identifier)
        if user is None:
            user = await self.user_repo.get_by_username(identifier)
        if user is None or not user.is_active:
            raise AuthError('Credenciales invalidas.', status_code=401)
        if not self.verify_password(password, user.password_hash):
            raise AuthError('Credenciales invalidas.', status_code=401)
        return await self._issue_session_tokens(user, ip_address=ip_address)

    async def login_with_pin(self, identifier: str, pin: str, *, ip_address: str | None = None) -> AuthResult:
        normalized_identifier = identifier.strip()
        normalized_pin = pin.strip()
        self._validate_pin(normalized_pin)
        user = await self.user_repo.get_by_email(normalized_identifier)
        if user is None:
            user = await self.user_repo.get_by_username(normalized_identifier)
        if user is None or not user.is_active:
            raise AuthError('Credenciales invalidas.', status_code=401)
        if not user.pin_hash or user.pin_length not in {4, 6}:
            raise AuthError('El usuario no tiene PIN configurado.', status_code=400)
        valid_pin, legacy_hash = self._verify_pin(normalized_pin, user.pin_hash)
        if not valid_pin:
            raise AuthError('Credenciales invalidas.', status_code=401)
        if legacy_hash:
            upgraded = await self.user_repo.set_pin(
                user.id,
                pin_hash=self._hash_pin(normalized_pin),
                pin_length=user.pin_length,
            )
            if upgraded is not None:
                user = upgraded
        return await self._issue_session_tokens(user, ip_address=ip_address)


    async def refresh(self, refresh_token: str, *, ip_address: str | None = None) -> AuthResult:
        normalized_token = refresh_token.strip()
        if not normalized_token:
            raise AuthError('Refresh token requerido.', status_code=400)
        payload = self._decode_token_payload(normalized_token, expected_kind='refresh')
        statement = select(SessionToken).where(
            SessionToken.token_hash == self._token_hash(normalized_token),
            SessionToken.expires_at > datetime.now(timezone.utc),
        )
        session_row = (await self.session.scalars(statement)).first()
        if session_row is None:
            raise AuthError('Refresh token expirado.', status_code=401)
        user = await self.user_repo.get_by_id(int(payload['sub']))
        if user is None or not user.is_active:
            raise AuthError('Usuario no disponible.', status_code=401)
        await self.session.delete(session_row)
        return await self._issue_session_tokens(user, ip_address=ip_address)

    async def list_profiles(self, user_id: int | None = None) -> list[User]:
        if user_id is None:
            return await self.user_repo.list_active()
        user = await self.user_repo.get_by_id(user_id)
        if user is None or not user.is_active:
            return []
        return [user]

    async def update_profile(self, user_id: int, *, username: str | None = None, email: str | None = None) -> User:
        user = await self.user_repo.get_by_id(user_id)
        if user is None or not user.is_active:
            raise AuthError('Perfil no disponible.', status_code=404)

        normalized_username = username.strip() if username is not None else user.username
        normalized_email = self._normalize_email(email) if email is not None else user.email

        if not normalized_username:
            raise AuthError('El nombre de usuario es obligatorio.')

        existing = await self.user_repo.get_by_username(normalized_username)
        if existing is not None and existing.id != user_id:
            raise AuthError('Ese nombre de usuario ya existe.')

        if normalized_email:
            existing_email = await self.user_repo.get_by_email(normalized_email)
            if existing_email is not None and existing_email.id != user_id:
                raise AuthError('Ese correo ya existe.')

        updated = await self.user_repo.update_profile(
            user_id,
            username=normalized_username,
            email=normalized_email,
            update_email=True,
        )
        if updated is None:
            raise AuthError('Perfil no disponible.', status_code=404)
        await self.session.commit()
        await self.session.refresh(updated)
        return updated

    async def update_pin(self, user_id: int, *, pin: str | None) -> User:
        user = await self.user_repo.get_by_id(user_id)
        if user is None or not user.is_active:
            raise AuthError('Perfil no disponible.', status_code=404)

        pin_hash = None
        pin_length = 0
        if pin:
            pin_length = self._validate_pin(pin)
            pin_hash = self._hash_pin(pin)

        updated = await self.user_repo.set_pin(user_id, pin_hash=pin_hash, pin_length=pin_length)
        if updated is None:
            raise AuthError('Perfil no disponible.', status_code=404)
        await self.session.commit()
        await self.session.refresh(updated)
        return updated

    async def deactivate_profile(self, user_id: int) -> None:
        user = await self.user_repo.get_by_id(user_id)
        if user is None or not user.is_active:
            raise AuthError('Perfil no disponible.', status_code=404)
        deactivated = await self.user_repo.deactivate(user_id)
        if not deactivated:
            raise AuthError('Perfil no disponible.', status_code=404)
        await self.session.execute(delete(SessionToken).where(SessionToken.user_id == user_id))
        await self.session.commit()

    async def logout(self, token: str) -> None:
        payload = self._decode_token_payload(token)
        deleted = await self.session.execute(
            delete(SessionToken).where(SessionToken.user_id == int(payload['sub']))
        )
        if not deleted.rowcount:
            raise AuthError('Sesion expirada.', status_code=401)
        await self.session.commit()

    async def get_current_user_from_token(self, token: str) -> User:
        payload = self._decode_token_payload(token, expected_kind='access')
        statement = select(SessionToken).where(
            SessionToken.token_hash == self._token_hash(token),
            SessionToken.expires_at > datetime.now(timezone.utc),
        )
        session_row = (await self.session.scalars(statement)).first()
        if session_row is None:
            raise AuthError('Sesion expirada.', status_code=401)
        user = await self.user_repo.get_by_id(int(payload['sub']))
        if user is None or not user.is_active:
            raise AuthError('Usuario no disponible.', status_code=401)
        return user

    async def get_user_from_token(self, token: str) -> User:
        return await self.get_current_user_from_token(token)
