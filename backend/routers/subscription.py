from __future__ import annotations

import json
from dataclasses import asdict

from fastapi import APIRouter, Depends, HTTPException, Request, status

from backend.middleware import get_current_user, get_subscription_use_cases
from backend.schemas.export import CheckoutResponse, SubscriptionStatusRead, WebhookResponse
from backend.services.subscription_service import (
    SubscriptionCheckoutError,
    SubscriptionWebhookError,
    SubscriptionWebhookSignatureError,
)

router = APIRouter(prefix='/subscription', tags=['subscription'])


@router.get('/status', response_model=SubscriptionStatusRead)
async def status_endpoint(current_user=Depends(get_current_user), subscription_uc=Depends(get_subscription_use_cases)):
    status_payload = await subscription_uc.status(current_user.id)
    return SubscriptionStatusRead(**asdict(status_payload))


@router.post('/checkout', response_model=CheckoutResponse)
async def checkout_endpoint(current_user=Depends(get_current_user), subscription_uc=Depends(get_subscription_use_cases)):
    try:
        checkout_url = await subscription_uc.checkout(current_user.id)
    except SubscriptionCheckoutError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(exc),
        ) from exc
    if checkout_url is None:
        return CheckoutResponse(checkout_url=None, message='El usuario ya tiene acceso premium activo.')
    return CheckoutResponse(checkout_url=checkout_url, message='Checkout preparado.')


@router.post('/webhook', response_model=WebhookResponse)
async def webhook_endpoint(request: Request, subscription_uc=Depends(get_subscription_use_cases)):
    raw_body = await request.body()
    try:
        payload = json.loads(raw_body.decode('utf-8') or '{}')
    except json.JSONDecodeError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail='Payload JSON invalido.',
        ) from exc
    if not isinstance(payload, dict):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail='El webhook debe enviar un objeto JSON.',
        )

    try:
        message = await subscription_uc.webhook(
            payload,
            raw_body=raw_body,
            headers=dict(request.headers),
        )
    except SubscriptionWebhookSignatureError as exc:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(exc),
        ) from exc
    except SubscriptionWebhookError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc
    return WebhookResponse(ok=True, message=message)
