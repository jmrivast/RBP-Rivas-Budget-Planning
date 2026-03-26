from __future__ import annotations

from collections import defaultdict, deque
from threading import Lock
from time import monotonic

from fastapi import HTTPException, Request, status


class _RateLimitStore:
    def __init__(self) -> None:
        self._entries: dict[str, deque[float]] = defaultdict(deque)
        self._lock = Lock()

    def hit(self, key: str, *, limit: int, window_seconds: int) -> bool:
        now = monotonic()
        cutoff = now - window_seconds
        with self._lock:
            window = self._entries[key]
            while window and window[0] <= cutoff:
                window.popleft()
            if len(window) >= limit:
                return False
            window.append(now)
            return True


_STORES: dict[str, _RateLimitStore] = {}
_STORES_LOCK = Lock()


def _store_for(bucket: str) -> _RateLimitStore:
    with _STORES_LOCK:
        store = _STORES.get(bucket)
        if store is None:
            store = _RateLimitStore()
            _STORES[bucket] = store
        return store


def _client_ip(request: Request) -> str:
    forwarded = request.headers.get('x-forwarded-for', '')
    if forwarded:
        return forwarded.split(',')[0].strip() or 'unknown'
    if request.client and request.client.host:
        return request.client.host
    return 'unknown'


def rate_limit_dependency(bucket: str, *, limit: int, window_seconds: int):
    store = _store_for(bucket)

    async def dependency(request: Request) -> None:
        key = f"{bucket}:{_client_ip(request)}"
        if store.hit(key, limit=limit, window_seconds=window_seconds):
            return
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail='Demasiadas solicitudes. Intenta de nuevo en breve.',
        )

    return dependency
