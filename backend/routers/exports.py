from __future__ import annotations

from fastapi import APIRouter, Depends
from fastapi.responses import Response

from backend.middleware import get_export_use_cases

router = APIRouter(prefix='/export', tags=['export'])


@router.get('/csv')
async def export_csv(
    year: int,
    month: int,
    cycle: int,
    export_uc=Depends(get_export_use_cases),
):
    filename, content = await export_uc.csv(year=year, month=month, cycle=cycle)
    return Response(content=content, media_type='text/csv', headers={'Content-Disposition': f'attachment; filename={filename}'})


@router.get('/pdf')
async def export_pdf(
    year: int,
    month: int,
    cycle: int,
    export_uc=Depends(get_export_use_cases),
):
    filename, content = await export_uc.pdf(year=year, month=month, cycle=cycle)
    return Response(content=content, media_type='application/pdf', headers={'Content-Disposition': f'attachment; filename={filename}'})
