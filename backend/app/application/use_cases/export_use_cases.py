from __future__ import annotations

from dataclasses import dataclass

from backend.app.domain.ports import ExportPort


@dataclass(slots=True)
class ExportUseCases:
    export: ExportPort

    async def csv(self, *, year: int, month: int, cycle: int) -> tuple[str, bytes]:
        return await self.export.build_csv(year=year, month=month, cycle=cycle)

    async def pdf(self, *, year: int, month: int, cycle: int) -> tuple[str, bytes]:
        return await self.export.build_pdf(year=year, month=month, cycle=cycle)
