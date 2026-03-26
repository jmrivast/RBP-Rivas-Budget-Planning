from __future__ import annotations

import csv
import io
from dataclasses import asdict
from datetime import datetime, timezone

from backend.services.finance_service import FinanceService


class ExportService:
    def __init__(self, finance_service: FinanceService) -> None:
        self.finance_service = finance_service

    async def build_csv(self, *, year: int, month: int, cycle: int) -> tuple[str, bytes]:
        dashboard = await self.finance_service.get_dashboard_data(year=year, month=month, cycle=cycle)
        buffer = io.StringIO()
        writer = csv.writer(buffer)
        writer.writerow(['field', 'value'])
        writer.writerow(['period_title', dashboard.period_title])
        writer.writerow(['salary', dashboard.salary])
        writer.writerow(['extra_income', dashboard.extra_income])
        writer.writerow(['period_savings', dashboard.period_savings])
        writer.writerow(['total_savings', dashboard.total_savings])
        writer.writerow(['total_expenses', dashboard.total_expenses])
        writer.writerow(['total_fixed', dashboard.total_fixed])
        writer.writerow(['total_loans', dashboard.total_loans])
        writer.writerow(['dinero_disponible', dashboard.dinero_disponible])
        writer.writerow([])
        writer.writerow(['recent_date', 'description', 'amount', 'categories', 'type'])
        for item in dashboard.recent_items:
            writer.writerow([
                item.get('date', ''),
                item.get('description', ''),
                item.get('amount', 0),
                item.get('categories', ''),
                item.get('type', ''),
            ])
        filename = f'rbp_export_{year}_{month:02d}_q{cycle}.csv'
        return filename, buffer.getvalue().encode('utf-8')

    async def build_pdf(self, *, year: int, month: int, cycle: int) -> tuple[str, bytes]:
        dashboard = await self.finance_service.get_dashboard_data(year=year, month=month, cycle=cycle)
        lines = [
            'RBP Finanzas Reporte',
            dashboard.period_title,
            '',
            f'Salario: {dashboard.salary:.2f}',
            f'Ingresos extra: {dashboard.extra_income:.2f}',
            f'Ahorro periodo: {dashboard.period_savings:.2f}',
            f'Gastos: {dashboard.total_expenses:.2f}',
            f'Pagos fijos: {dashboard.total_fixed:.2f}',
            f'Prestamos: {dashboard.total_loans:.2f}',
            f'Dinero disponible: {dashboard.dinero_disponible:.2f}',
            '',
            'Resumen generado: ' + datetime.now(timezone.utc).isoformat(),
        ]
        text = '\n'.join(lines)
        stream = f'BT /F1 12 Tf 50 780 Td ({text.replace("(", "[").replace(")", "]").replace(chr(10), ") Tj T* (")}) Tj ET'
        pdf = (
            '%PDF-1.4\n'
            '1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n'
            '2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n'
            '3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >> endobj\n'
            '4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n'
            f'5 0 obj << /Length {len(stream)} >> stream\n{stream}\nendstream endobj\n'
            'xref\n0 6\n0000000000 65535 f \n'
            '0000000010 00000 n \n0000000063 00000 n \n0000000122 00000 n \n0000000248 00000 n \n0000000318 00000 n \n'
            'trailer << /Size 6 /Root 1 0 R >>\nstartxref\n0\n%%EOF'
        )
        filename = f'rbp_export_{year}_{month:02d}_q{cycle}.pdf'
        return filename, pdf.encode('latin-1', errors='ignore')
