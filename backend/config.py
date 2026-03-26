from __future__ import annotations

import os
from dataclasses import dataclass
from functools import lru_cache

from dotenv import load_dotenv


load_dotenv()


@dataclass(slots=True)
class Settings:
    app_name: str = os.getenv("APP_NAME", "RBP API")
    app_env: str = os.getenv("APP_ENV", "development").lower()
    debug: bool = os.getenv("DEBUG", "false").lower() in {"1", "true", "yes", "on"}
    api_prefix: str = os.getenv("API_PREFIX", "/api")
    secret_key: str = os.getenv("SECRET_KEY", "rbp-dev-secret-change-me")
    jwt_algorithm: str = os.getenv("JWT_ALGORITHM", "HS256")
    access_token_expire_minutes: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440"))
    refresh_token_expire_days: int = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "30"))
    database_url: str = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./data/finanzas_app.db")
    cors_origins: tuple[str, ...] = tuple(
        origin.strip()
        for origin in os.getenv("CORS_ORIGINS", "http://localhost:3000,http://127.0.0.1:3000,http://localhost:8080,http://127.0.0.1:8080").split(",")
        if origin.strip()
    )
    billing_provider: str = os.getenv("BILLING_PROVIDER", "stub")
    stripe_secret_key: str = os.getenv("STRIPE_SECRET_KEY", "")
    stripe_price_id: str = os.getenv("STRIPE_PRICE_ID", "")
    stripe_success_url: str = os.getenv("STRIPE_SUCCESS_URL", "http://127.0.0.1:8000/?checkout=success")
    stripe_cancel_url: str = os.getenv("STRIPE_CANCEL_URL", "http://127.0.0.1:8000/?checkout=cancel")
    stripe_webhook_secret: str = os.getenv("STRIPE_WEBHOOK_SECRET", "")
    polar_checkout_url: str = os.getenv("POLAR_CHECKOUT_URL", "")
    polar_api_base_url: str = os.getenv("POLAR_API_BASE_URL", "https://sandbox-api.polar.sh")
    polar_access_token: str = os.getenv("POLAR_ACCESS_TOKEN", "")
    polar_organization_id: str = os.getenv("POLAR_ORGANIZATION_ID", "")
    polar_product_id: str = os.getenv("POLAR_PRODUCT_ID", "")
    polar_success_url: str = os.getenv("POLAR_SUCCESS_URL", "http://127.0.0.1:8000/?checkout=success")
    polar_return_url: str = os.getenv("POLAR_RETURN_URL", "http://127.0.0.1:8000/?checkout=cancel")
    polar_webhook_secret: str = os.getenv("POLAR_WEBHOOK_SECRET", "")
    google_client_id: str = os.getenv("GOOGLE_CLIENT_ID", "")

    @property
    def is_production(self) -> bool:
        return self.app_env == "production"

    @property
    def has_safe_secret_key(self) -> bool:
        secret = self.secret_key.strip()
        return bool(secret and secret != "rbp-dev-secret-change-me")

    @property
    def sync_database_url(self) -> str:
        return (
            self.database_url.replace("+aiosqlite", "")
            .replace("+asyncpg", "")
            .replace("sqlite:///./", "sqlite:///")
        )

    @property
    def jwt_secret_key(self) -> str:
        return self.secret_key

    @property
    def stripe_enabled(self) -> bool:
        return bool(self.stripe_secret_key and self.stripe_price_id)

    @property
    def should_bootstrap_schema(self) -> bool:
        return not self.is_production and self.database_url.startswith("sqlite")

    @property
    def billing_provider_name(self) -> str:
        return self.billing_provider.strip().lower() or "stub"

    @property
    def polar_enabled(self) -> bool:
        return bool(
            self.polar_checkout_url
            or (self.polar_api_base_url and self.polar_access_token and self.polar_product_id)
        )

    @property
    def google_enabled(self) -> bool:
        return bool(self.google_client_id)


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
