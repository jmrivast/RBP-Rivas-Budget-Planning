"""initial schema

Revision ID: 20260307_0001
Revises:
Create Date: 2026-03-07 18:30:00
"""

from __future__ import annotations

from alembic import op

from backend.database.base import Base
from backend.database import models  # noqa: F401

revision = "20260307_0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    Base.metadata.create_all(bind=bind)


def downgrade() -> None:
    bind = op.get_bind()
    Base.metadata.drop_all(bind=bind)
