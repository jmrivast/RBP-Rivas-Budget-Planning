from __future__ import annotations

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession

from backend.database import get_db
from backend.middleware import get_backup_use_cases, get_current_user
from backend.schemas.export import BackupRead

router = APIRouter(prefix='/backup', tags=['backup'])


@router.post('/create')
async def create_backup(
    current_user=Depends(get_current_user),
    backup_uc=Depends(get_backup_use_cases),
    session: AsyncSession = Depends(get_db),
):
    try:
        filename, path = await backup_uc.create(current_user.id)
        await session.commit()
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return FileResponse(path=path, media_type='application/octet-stream', filename=filename)


@router.post('/restore', response_model=BackupRead)
async def restore_backup(
    file: UploadFile = File(...),
    current_user=Depends(get_current_user),
    backup_uc=Depends(get_backup_use_cases),
    session: AsyncSession = Depends(get_db),
):
    try:
        row = await backup_uc.restore(current_user.id, await file.read())
        await session.commit()
    except Exception as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    return BackupRead.model_validate({
        'id': row.id,
        'user_id': row.user_id,
        'backup_file': row.backup_file,
        'backup_date': row.backup_date,
    })
