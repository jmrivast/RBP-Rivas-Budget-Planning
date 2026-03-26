from __future__ import annotations

import base64
import hashlib
import hmac
from collections.abc import Callable, Mapping
from dataclasses import dataclass
from datetime import datetime, timezone
from importlib import import_module
from typing import Any
from urllib.parse import urlencode

import httpx

from backend.config import Settings, get_settings
from backend.repositories.subscription_repo import SubscriptionRepository


@dataclass(slots=True)
class SubscriptionStatus:
    plan: str
    status: str
    is_premium: bool
    trial_end: datetime | None
    current_period_end: datetime | None
    expense_limit_per_period: int | None
    billing_provider: str


class SubscriptionError(Exception):
    pass


class SubscriptionCheckoutError(SubscriptionError):
    pass


class SubscriptionWebhookError(SubscriptionError):
    pass


class SubscriptionWebhookSignatureError(SubscriptionWebhookError):
    pass


class SubscriptionService:
    def __init__(
        self,
        repo: SubscriptionRepository,
        *,
        settings_obj: Settings | None = None,
        stripe_sdk: Any | None = None,
        http_client_factory: Callable[[], Any] | None = None,
    ) -> None:
        self.repo = repo
        self.settings = settings_obj or get_settings()
        self._stripe_sdk = stripe_sdk
        self._http_client_factory = http_client_factory or (
            lambda: httpx.AsyncClient(timeout=20.0)
        )

    def _status_provider_name(self) -> str:
        provider = self.settings.billing_provider_name
        if provider != 'stub':
            return provider
        if self.settings.polar_enabled:
            return 'polar'
        if self.settings.stripe_enabled:
            return 'stripe'
        return 'stub'

    def _checkout_provider_name(self) -> str:
        provider = self._status_provider_name()
        return 'stripe' if provider == 'stub' else provider

    def _build_checkout_placeholder(self, provider: str) -> str:
        if provider == 'polar' and self.settings.polar_checkout_url:
            query = urlencode({'source': 'rbp', 'provider': provider})
            separator = '&' if '?' in self.settings.polar_checkout_url else '?'
            return f'{self.settings.polar_checkout_url}{separator}{query}'
        return f'https://example.com/{provider}-checkout-not-configured'

    def _get_stripe_sdk(self):
        if self._stripe_sdk is not None:
            return self._stripe_sdk
        try:
            self._stripe_sdk = import_module('stripe')
        except ImportError:
            self._stripe_sdk = None
        return self._stripe_sdk

    async def get_status(self, user_id: int) -> SubscriptionStatus:
        item = await self.repo.ensure_default(user_id)
        await self.repo.session.commit()
        is_premium = item.plan == 'premium' and item.status in {'active', 'trialing', 'past_due'}
        expense_limit = None if is_premium else 15
        return SubscriptionStatus(
            plan=item.plan,
            status=item.status,
            is_premium=is_premium,
            trial_end=item.trial_end,
            current_period_end=item.current_period_end,
            expense_limit_per_period=expense_limit,
            billing_provider=self._status_provider_name(),
        )

    async def create_checkout(self, user_id: int) -> str | None:
        item = await self.repo.ensure_default(user_id)
        if item.plan == 'premium' and item.status in {'active', 'trialing', 'past_due'}:
            await self.repo.session.commit()
            return None

        provider = self._checkout_provider_name()
        if provider == 'stripe':
            return await self._create_stripe_checkout(user_id)
        if provider == 'polar':
            return await self._create_polar_checkout(user_id)

        await self.repo.session.commit()
        return self._build_checkout_placeholder(provider)

    async def _create_stripe_checkout(self, user_id: int) -> str:
        stripe_sdk = self._get_stripe_sdk()
        if not self.settings.stripe_enabled or stripe_sdk is None:
            await self.repo.session.commit()
            return self._build_checkout_placeholder('stripe')

        stripe_sdk.api_key = self.settings.stripe_secret_key
        try:
            checkout = stripe_sdk.checkout.Session.create(
                mode='subscription',
                line_items=[{'price': self.settings.stripe_price_id, 'quantity': 1}],
                success_url=self.settings.stripe_success_url,
                cancel_url=self.settings.stripe_cancel_url,
                metadata={'user_id': str(user_id)},
                subscription_data={'metadata': {'user_id': str(user_id)}},
            )
        except Exception:
            await self.repo.session.commit()
            return self._build_checkout_placeholder('stripe')
        await self.repo.update_status(
            user_id,
            status='pending_checkout',
            provider_customer_id=str(getattr(checkout, 'customer', '') or '') or None,
            provider_subscription_id=str(getattr(checkout, 'subscription', '') or '') or None,
        )
        await self.repo.session.commit()
        return getattr(checkout, 'url', None) or self._build_checkout_placeholder('stripe')

    def _polar_checkout_payload(self, user_id: int) -> dict[str, object]:
        payload: dict[str, object] = {
            'products': [self.settings.polar_product_id],
            'external_customer_id': str(user_id),
            'metadata': {
                'user_id': str(user_id),
                'source': 'rbp',
            },
            'success_url': self.settings.polar_success_url,
            'return_url': self.settings.polar_return_url,
        }
        if self.settings.polar_organization_id:
            payload['organization_id'] = self.settings.polar_organization_id
        return payload

    async def _create_polar_checkout(self, user_id: int) -> str:
        if not (self.settings.polar_access_token and self.settings.polar_product_id):
            await self.repo.update_status(user_id, status='pending_checkout')
            await self.repo.session.commit()
            return self._build_checkout_placeholder('polar')

        headers = {
            'Authorization': f'Bearer {self.settings.polar_access_token}',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
        }
        url = f"{self.settings.polar_api_base_url.rstrip('/')}/v1/checkouts/"
        async with self._http_client_factory() as client:
            try:
                response = await client.post(
                    url,
                    headers=headers,
                    json=self._polar_checkout_payload(user_id),
                )
            except httpx.HTTPError as exc:
                raise SubscriptionCheckoutError('No fue posible contactar Polar para crear el checkout.') from exc

        if response.status_code >= 400:
            detail = response.text.strip() or f'HTTP {response.status_code}'
            raise SubscriptionCheckoutError(f'Polar rechazo el checkout: {detail}')

        data = response.json()
        checkout_url = data.get('url') or data.get('checkout_url')
        if not isinstance(checkout_url, str) or not checkout_url:
            raise SubscriptionCheckoutError('Polar no devolvio una URL de checkout valida.')

        customer_id = self._string_or_none(data.get('customer_id'))
        subscription_id = self._string_or_none(data.get('subscription_id'))
        await self.repo.update_status(
            user_id,
            status='pending_checkout',
            provider_customer_id=customer_id,
            provider_subscription_id=subscription_id,
        )
        await self.repo.session.commit()
        return checkout_url

    @staticmethod
    def _string_or_none(value: object) -> str | None:
        if isinstance(value, str) and value.strip():
            return value.strip()
        return None

    @staticmethod
    def _to_datetime(value: object) -> datetime | None:
        if value in {None, ''}:
            return None
        if isinstance(value, datetime):
            return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
        if isinstance(value, (int, float)):
            return datetime.fromtimestamp(value, tz=timezone.utc)
        if isinstance(value, str):
            candidate = value.strip()
            if not candidate:
                return None
            try:
                normalized = candidate.replace('Z', '+00:00')
                parsed = datetime.fromisoformat(normalized)
            except ValueError:
                return None
            return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
        return None

    @staticmethod
    def _coerce_user_id(raw_user_id: object) -> int | None:
        if raw_user_id in {None, ''}:
            return None
        try:
            return int(raw_user_id)
        except (TypeError, ValueError):
            return None

    @classmethod
    def _metadata_user_id(cls, data: dict[str, object]) -> int | None:
        metadata = data.get('metadata') if isinstance(data.get('metadata'), dict) else {}
        raw_user_id = metadata.get('user_id') if isinstance(metadata, dict) else None
        return cls._coerce_user_id(raw_user_id)

    @classmethod
    def _external_customer_user_id(cls, data: dict[str, object]) -> int | None:
        direct_id = cls._coerce_user_id(data.get('external_customer_id'))
        if direct_id is not None:
            return direct_id
        customer = data.get('customer') if isinstance(data.get('customer'), dict) else {}
        if isinstance(customer, dict):
            return cls._coerce_user_id(customer.get('external_id'))
        return None

    async def _resolve_target_user_id(self, data: dict[str, object]) -> int | None:
        user_id = self._metadata_user_id(data)
        if user_id is not None:
            return user_id

        user_id = self._external_customer_user_id(data)
        if user_id is not None:
            return user_id

        customer = data.get('customer') if isinstance(data.get('customer'), dict) else {}
        customer_id = data.get('customer') if isinstance(data.get('customer'), str) else None
        if customer_id is None and isinstance(customer, dict):
            customer_id = self._string_or_none(customer.get('id'))
        if customer_id:
            row = await self.repo.get_by_provider_customer_id(customer_id)
            if row is not None:
                return row.user_id

        subscription_id = self._string_or_none(data.get('subscription'))
        if subscription_id is None:
            subscription_id = self._string_or_none(data.get('subscription_id'))
        if subscription_id is None:
            subscription_id = self._string_or_none(data.get('id'))
        if subscription_id:
            row = await self.repo.get_by_provider_subscription_id(subscription_id)
            if row is not None:
                return row.user_id

        return None

    @staticmethod
    def _normalize_headers(headers: Mapping[str, str] | None) -> dict[str, str]:
        if headers is None:
            return {}
        return {str(key).lower(): value for key, value in headers.items()}

    @staticmethod
    def _signed_content(message_id: str, timestamp: str, raw_body: bytes) -> bytes:
        return message_id.encode('utf-8') + b'.' + timestamp.encode('utf-8') + b'.' + raw_body

    @staticmethod
    def _parse_signature_header(signature_header: str) -> list[str]:
        signatures: list[str] = []
        for part in signature_header.replace(';', ' ').split():
            token = part.strip()
            if not token:
                continue
            if ',' in token:
                version, candidate = token.split(',', 1)
                if version.strip() in {'v1', 'v0'} and candidate.strip():
                    signatures.append(candidate.strip())
                    continue
            signatures.append(token)
        return signatures

    def _verify_polar_webhook_signature(
        self,
        raw_body: bytes | None,
        headers: Mapping[str, str] | None,
    ) -> None:
        if not self.settings.polar_webhook_secret:
            if self.settings.is_production:
                raise SubscriptionWebhookSignatureError('POLAR_WEBHOOK_SECRET no esta configurado.')
            return
        if raw_body is None:
            raise SubscriptionWebhookSignatureError('El webhook requiere el body crudo para validar la firma.')

        normalized_headers = self._normalize_headers(headers)
        message_id = normalized_headers.get('webhook-id', '')
        timestamp = normalized_headers.get('webhook-timestamp', '')
        signature_header = normalized_headers.get('webhook-signature', '')
        if not (message_id and timestamp and signature_header):
            raise SubscriptionWebhookSignatureError('Faltan headers de firma del webhook Polar.')

        try:
            timestamp_value = int(timestamp)
        except ValueError as exc:
            raise SubscriptionWebhookSignatureError('Timestamp de webhook invalido.') from exc
        now = int(datetime.now(timezone.utc).timestamp())
        if abs(now - timestamp_value) > 600:
            raise SubscriptionWebhookSignatureError('Webhook fuera de la ventana de tolerancia.')

        expected_signature = base64.b64encode(
            hmac.new(
                self.settings.polar_webhook_secret.encode('utf-8'),
                self._signed_content(message_id, timestamp, raw_body),
                hashlib.sha256,
            ).digest()
        ).decode('utf-8')
        valid_signatures = self._parse_signature_header(signature_header)
        if not any(hmac.compare_digest(expected_signature, candidate) for candidate in valid_signatures):
            raise SubscriptionWebhookSignatureError('Firma de webhook Polar invalida.')

    async def process_webhook(
        self,
        payload: dict[str, object],
        *,
        raw_body: bytes | None = None,
        headers: Mapping[str, str] | None = None,
    ) -> str:
        provider = self._checkout_provider_name()
        if provider == 'polar':
            self._verify_polar_webhook_signature(raw_body, headers)
        event_type = str(payload.get('type', 'unknown'))
        data_root = payload.get('data') if isinstance(payload.get('data'), dict) else {}
        data = data_root.get('object') if isinstance(data_root.get('object'), dict) else data_root
        user_id = await self._resolve_target_user_id(data)

        if event_type == 'customer.state_changed':
            return await self._process_customer_state_changed(user_id, data)
        return await self._process_subscription_like_event(user_id, event_type, data)

    async def _process_customer_state_changed(
        self,
        user_id: int | None,
        data: dict[str, object],
    ) -> str:
        if user_id is None:
            return 'Webhook recibido sin user_id resolvible: customer.state_changed'

        active_subscriptions = data.get('active_subscriptions')
        active_items = active_subscriptions if isinstance(active_subscriptions, list) else []
        if not active_items:
            await self.repo.update_status(user_id, plan='free', status='canceled')
            await self.repo.session.commit()
            return f'Suscripcion degradada para user_id={user_id}: customer.state_changed'

        first_active = active_items[0] if isinstance(active_items[0], dict) else {}
        subscription_id = self._string_or_none(first_active.get('id'))
        customer_id = self._string_or_none(first_active.get('customer_id'))
        period_end = self._to_datetime(first_active.get('current_period_end'))
        status = self._string_or_none(first_active.get('status')) or 'active'
        await self.repo.update_status(
            user_id,
            plan='premium',
            status=status,
            provider_customer_id=customer_id,
            provider_subscription_id=subscription_id,
            current_period_end=period_end,
        )
        await self.repo.session.commit()
        return f'Suscripcion premium actualizada para user_id={user_id}: customer.state_changed'

    async def _process_subscription_like_event(
        self,
        user_id: int | None,
        event_type: str,
        data: dict[str, object],
    ) -> str:
        customer = data.get('customer') if isinstance(data.get('customer'), dict) else {}
        customer_id = data.get('customer') if isinstance(data.get('customer'), str) else None
        if customer_id is None and isinstance(customer, dict):
            customer_id = self._string_or_none(customer.get('id'))
        subscription_id = self._string_or_none(data.get('subscription'))
        if subscription_id is None:
            subscription_id = self._string_or_none(data.get('subscription_id'))
        if subscription_id is None:
            subscription_id = self._string_or_none(data.get('id'))
        period_end = self._to_datetime(data.get('current_period_end'))
        status = self._string_or_none(data.get('status')) or ''

        if user_id is None:
            return f'Webhook recibido sin user_id resolvible: {event_type}'

        premium_events = {
            'checkout.session.completed',
            'customer.subscription.created',
            'customer.subscription.updated',
            'invoice.paid',
            'subscription.created',
            'subscription.active',
            'subscription.updated',
            'subscription.uncanceled',
        }
        past_due_events = {
            'invoice.payment_failed',
            'subscription.past_due',
            'subscription.unpaid',
        }
        downgrade_events = {
            'customer.subscription.deleted',
            'subscription.canceled',
            'subscription.revoked',
        }

        if event_type in premium_events:
            await self.repo.update_status(
                user_id,
                plan='premium',
                status=status or 'active',
                provider_customer_id=customer_id,
                provider_subscription_id=subscription_id,
                current_period_end=period_end,
            )
            await self.repo.session.commit()
            return f'Suscripcion premium actualizada para user_id={user_id}: {event_type}'

        if event_type in past_due_events:
            await self.repo.update_status(
                user_id,
                plan='premium',
                status='past_due',
                provider_customer_id=customer_id,
                provider_subscription_id=subscription_id,
                current_period_end=period_end,
            )
            await self.repo.session.commit()
            return f'Suscripcion premium actualizada para user_id={user_id}: {event_type}'

        if event_type in downgrade_events:
            next_plan = 'premium' if status in {'active', 'trialing', 'past_due'} else 'free'
            next_status = status or ('canceled' if next_plan == 'free' else 'active')
            await self.repo.update_status(
                user_id,
                plan=next_plan,
                status=next_status,
                provider_customer_id=customer_id,
                provider_subscription_id=subscription_id,
                current_period_end=period_end,
            )
            await self.repo.session.commit()
            action = 'actualizada' if next_plan == 'premium' else 'degradada'
            return f'Suscripcion {action} para user_id={user_id}: {event_type}'

        return f'Webhook recibido sin accion aplicada: {event_type}'

    async def can_create_expense(self, user_id: int, period_expense_count: int) -> bool:
        status = await self.get_status(user_id)
        if status.is_premium:
            return True
        trial_end = status.trial_end
        if trial_end is not None:
            if trial_end.tzinfo is None:
                trial_end = trial_end.replace(tzinfo=timezone.utc)
            if trial_end > datetime.now(timezone.utc):
                return True
        limit = status.expense_limit_per_period or 15
        return period_expense_count < limit

