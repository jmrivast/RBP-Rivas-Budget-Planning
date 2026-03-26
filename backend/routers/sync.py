from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends

from backend.middleware import get_current_user
from backend.schemas.sync import (
    IncrementalSyncRequest,
    IncrementalSyncResponse,
    ManualSyncRequest,
    ManualSyncResponse,
)

router = APIRouter(prefix='/sync', tags=['sync'])


@router.post('/manual', response_model=ManualSyncResponse)
async def manual_sync(payload: ManualSyncRequest, current_user=Depends(get_current_user)):
    conflict_count = sum(
        1 for rule in payload.plan.rules if rule.strategy == 'manual_review'
    )
    completed_at = datetime.now(timezone.utc).isoformat()
    return ManualSyncResponse(
        success=True,
        message=(
            f'Sync inicial aceptado para {len(payload.plan.rules)} entidades del usuario '
            f'{current_user.id}. A partir de este baseline se habilita el incremental por entidad.'
        ),
        synced_entities=len(payload.plan.rules),
        conflicts_detected=conflict_count,
        completed_at=completed_at,
        next_step='Enviar deltas por entidad y activar auto-sync incremental despues del baseline.',
        remote_accepted=True,
    )


@router.post('/incremental', response_model=IncrementalSyncResponse)
async def incremental_sync(payload: IncrementalSyncRequest, current_user=Depends(get_current_user)):
    completed_at = datetime.now(timezone.utc).isoformat()
    changed = payload.changes_detected or payload.local_cursor != payload.previous_cursor
    message = (
        f'Delta aceptado para {payload.entity} del usuario {current_user.id}.'
        if changed
        else f'Sin cambios nuevos para {payload.entity}.'
    )
    return IncrementalSyncResponse(
        success=True,
        entity=payload.entity,
        accepted=True,
        changed=changed,
        conflicts_detected=0,
        completed_at=completed_at,
        server_cursor=payload.local_cursor or completed_at,
        trigger=payload.trigger,
        message=message,
        remote_accepted=True,
    )
