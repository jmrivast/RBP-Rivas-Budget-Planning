from __future__ import annotations

from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from backend.config import settings
from backend.database.engine import init_db
from backend.database import models  # noqa: F401
from backend.routers import (
    auth,
    backup,
    categories,
    dashboard,
    debts,
    expenses,
    exports,
    fixed_payments,
    income,
    loans,
    savings,
    settings as settings_router,
    subscription,
    sync,
)

FRONTEND_DIR = Path(__file__).resolve().parent.parent / 'frontend'


@asynccontextmanager
async def lifespan(_: FastAPI):
    if settings.is_production and not settings.has_safe_secret_key:
        raise RuntimeError('SECRET_KEY debe definirse con un valor seguro en produccion.')
    if settings.should_bootstrap_schema:
        await init_db()
    yield


app = FastAPI(title=settings.app_name, lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=list(settings.cors_origins) or ['*'],
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)

app.include_router(auth.router, prefix=settings.api_prefix)
app.include_router(backup.router, prefix=settings.api_prefix)
app.include_router(categories.router, prefix=settings.api_prefix)
app.include_router(dashboard.router, prefix=settings.api_prefix)
app.include_router(debts.router, prefix=settings.api_prefix)
app.include_router(expenses.router, prefix=settings.api_prefix)
app.include_router(exports.router, prefix=settings.api_prefix)
app.include_router(fixed_payments.router, prefix=settings.api_prefix)
app.include_router(income.router, prefix=settings.api_prefix)
app.include_router(loans.router, prefix=settings.api_prefix)
app.include_router(savings.router, prefix=settings.api_prefix)
app.include_router(settings_router.router, prefix=settings.api_prefix)
app.include_router(subscription.router, prefix=settings.api_prefix)
app.include_router(sync.router, prefix=settings.api_prefix)

if FRONTEND_DIR.exists():
    app.mount('/frontend', StaticFiles(directory=FRONTEND_DIR), name='frontend')


@app.get('/health')
async def health():
    return {'status': 'ok'}


@app.get('/manifest.json', include_in_schema=False)
async def manifest():
    return FileResponse(FRONTEND_DIR / 'manifest.json', media_type='application/manifest+json')


@app.get('/sw.js', include_in_schema=False)
async def service_worker():
    return FileResponse(
        FRONTEND_DIR / 'sw.js',
        media_type='application/javascript',
        headers={'Service-Worker-Allowed': '/'},
    )


@app.get('/offline.html', include_in_schema=False)
async def offline_page():
    return FileResponse(FRONTEND_DIR / 'offline.html')


@app.get('/', include_in_schema=False)
async def frontend_index():
    if FRONTEND_DIR.exists():
        return FileResponse(FRONTEND_DIR / 'index.html')
    return {'message': 'frontend not available'}



