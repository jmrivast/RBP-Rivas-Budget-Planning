"""
RBP (RIVAS BUDGET PLANNING) – Aplicación de finanzas personal.
Dashboard quincenal con navegación, gastos, pagos fijos, préstamos,
ahorro (depósitos/retiros + metas), ingresos/salario, gráficas por
categoría, exportación CSV, reportes PDF estéticos y alerta de quincena.
"""
from __future__ import annotations

import base64, csv, ctypes, io, json, logging, math, os, re, shutil, sys, webbrowser, zipfile
from multiprocessing import freeze_support
from calendar import monthrange
from collections import defaultdict
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional
from urllib import error as urlerror
from urllib import request as urlrequest

import flet as ft
from fpdf import FPDF

try:
    from src.config import BASE_DIR, DB_PATH, BACKUP_DIR, DEFAULT_CATEGORIES
    from src.db.database import Database
    from src.utils.backup import BackupManager
    from src.utils.helpers import format_currency, get_quincenal_cycle
except ModuleNotFoundError:
    import sys
    _ROOT = Path(__file__).resolve().parents[2]
    if str(_ROOT) not in sys.path:
        sys.path.insert(0, str(_ROOT))
    from src.config import BASE_DIR, DB_PATH, BACKUP_DIR, DEFAULT_CATEGORIES
    from src.db.database import Database
    from src.utils.backup import BackupManager
    from src.utils.helpers import format_currency, get_quincenal_cycle

logging.basicConfig(level=logging.INFO,
                    format="%(asctime)s %(name)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

# ── paleta ──────────────────────────────────────────────────────────────
_PRIMARY   = "#1565C0"
_PRIMARY_L = "#E3F2FD"
_CARD_BG   = "#FFFFFF"
_CARD_BD   = "#E0E0E0"
_SUBTITLE  = "#757575"
_SUCCESS   = "#43A047"
_ERROR     = "#E53935"
_WARN      = "#FB8C00"

REPORTS_DIR = BASE_DIR / "reportes"
APP_VERSION = "1.3.0-beta.2"
GITHUB_RELEASE_LATEST_API = "https://api.github.com/repos/jmrivast/RBP-Rivas-Budget-Planning/releases/latest"
GITHUB_RELEASES_API = "https://api.github.com/repos/jmrivast/RBP-Rivas-Budget-Planning/releases?per_page=25"
try:
    REPORTS_DIR.mkdir(exist_ok=True)
except Exception:
    pass

# ── icono base64 (preferir Untitled.png) ────────────────────────────────
_ICON_B64: Optional[str] = None
_ICON_PATH: Optional[Path] = None

def _asset_search_dirs() -> List[Path]:
    dirs: List[Path] = [BASE_DIR, BASE_DIR / "_internal"]
    meipass = getattr(sys, "_MEIPASS", None)
    if meipass:
        dirs.extend([Path(meipass), Path(meipass) / "_internal"])
    try:
        this_dir = Path(__file__).resolve().parent
        dirs.extend([this_dir, this_dir.parent, this_dir.parent.parent])
    except Exception:
        pass
    unique: List[Path] = []
    seen = set()
    for d in dirs:
        key = str(d)
        if key not in seen:
            seen.add(key)
            unique.append(d)
    return unique

for _dir in _asset_search_dirs():
    for _name in ["Untitled.png", "icon.png", "Diseño sin título.png"]:
        _cand = _dir / _name
        if _cand.exists():
            _ICON_PATH = _cand
            try:
                with open(_cand, "rb") as _f:
                    _ICON_B64 = base64.b64encode(_f.read()).decode()
            except Exception:
                pass
            break
    if _ICON_B64:
        break

# ── colores de gráfica ─────────────────────────────────────────────────
_PIE_COLORS = ["#1565C0","#43A047","#E53935","#FB8C00","#8E24AA",
               "#00897B","#F4511E","#3949AB","#C0CA33","#6D4C41"]


# ───────────────────────── helpers quincena ─────────────────────────────
def _qlabel(y: int, m: int, c: int) -> str:
    ms = {1:"Ene",2:"Feb",3:"Mar",4:"Abr",5:"May",6:"Jun",
          7:"Jul",8:"Ago",9:"Sep",10:"Oct",11:"Nov",12:"Dic"}
    rng = "1-15" if c == 1 else f"16-{monthrange(y,m)[1]}"
    return f"{rng} {ms[m]} {y}  (Q{c})"

def _prev_q(y,m,c):
    if c==2: return y,m,1
    if m==1: return y-1,12,2
    return y,m-1,2

def _next_q(y,m,c):
    if c==1: return y,m,2
    if m==12: return y+1,1,1
    return y,m+1,1


# ───────────────────────── PDF estético ────────────────────────────────
def _pdf_header(pdf: FPDF, icon_path: Optional[Path]):
    """Barra azul + logo."""
    pdf.set_fill_color(21, 101, 192)        # _PRIMARY
    pdf.rect(0, 0, 210, 28, "F")
    if icon_path and icon_path.exists():
        try:
            pdf.image(str(icon_path), x=10, y=4, h=20)
        except Exception:
            pass
    pdf.set_font("Helvetica", "B", 18)
    pdf.set_text_color(255, 255, 255)
    pdf.set_xy(35, 6)
    pdf.cell(0, 14, "RBP  -  Rivas Budget Planning", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(8)

def _pdf_section(pdf: FPDF, title: str):
    pdf.set_fill_color(21, 101, 192)
    pdf.set_text_color(255, 255, 255)
    pdf.set_font("Helvetica", "B", 12)
    pdf.cell(0, 9, f"  {title}", new_x="LMARGIN", new_y="NEXT", fill=True)
    pdf.set_text_color(0, 0, 0)
    pdf.ln(3)

def _pdf_kv(pdf: FPDF, label: str, value: str, bold_value=False):
    pdf.set_font("Helvetica", "", 10)
    pdf.cell(55, 7, label, new_x="RIGHT")
    pdf.set_font("Helvetica", "B" if bold_value else "", 10)
    pdf.cell(0, 7, value, new_x="LMARGIN", new_y="NEXT")

def _pdf_table_header(pdf: FPDF, cols: list):
    pdf.set_font("Helvetica", "B", 9)
    pdf.set_fill_color(227, 242, 253)       # _PRIMARY_L
    for w, t in cols:
        pdf.cell(w, 7, t, border=1, fill=True)
    pdf.ln()
    pdf.set_font("Helvetica", "", 9)

def generate_pdf_report(
    title, period_label, expenses, fixed_payments, loans,
    total_savings, salary, extra_income, categories_by_id, output_path,
    icon_path: Optional[Path] = None,
):
    pdf = FPDF()
    pdf.add_page()
    pdf.set_auto_page_break(auto=True, margin=15)
    _pdf_header(pdf, icon_path)
    pdf.set_text_color(0, 0, 0)
    pdf.set_font("Helvetica", "", 10)
    pdf.cell(0, 7, period_label, new_x="LMARGIN", new_y="NEXT", align="C")
    pdf.cell(0, 6, f"Generado: {datetime.now():%d/%m/%Y %H:%M}",
             new_x="LMARGIN", new_y="NEXT", align="C")
    pdf.ln(4)

    t_exp = sum(float(e["amount"]) for e in expenses)
    t_fix = sum(float(p["amount"]) for p in fixed_payments)
    t_loan = sum(float(l["amount"]) for l in loans if not l.get("is_paid"))
    d_ini = salary + extra_income - total_savings
    d_disp = d_ini - t_exp - t_fix - t_loan

    _pdf_section(pdf, "Resumen Financiero")
    _pdf_kv(pdf, "Salario:", f"RD${salary:,.2f}")
    _pdf_kv(pdf, "Ingresos extras:", f"RD${extra_income:,.2f}")
    _pdf_kv(pdf, "Ahorro total:", f"RD${total_savings:,.2f}")
    _pdf_kv(pdf, "Dinero inicial:", f"RD${d_ini:,.2f}")
    _pdf_kv(pdf, "Total gastos:", f"RD${t_exp:,.2f}")
    _pdf_kv(pdf, "Pagos fijos:", f"RD${t_fix:,.2f}")
    _pdf_kv(pdf, "Prestamos pend.:", f"RD${t_loan:,.2f}")
    _pdf_kv(pdf, "Dinero disponible:", f"RD${d_disp:,.2f}", bold_value=True)
    pdf.ln(3)

    if expenses:
        _pdf_section(pdf, "Gastos")
        cols = [(28,"Fecha"),(68,"Descripcion"),(38,"Categoria"),(34,"Monto")]
        _pdf_table_header(pdf, cols)
        for e in expenses:
            cn = []
            if e.get("category_ids"):
                for cid in str(e["category_ids"]).split(","):
                    cid = cid.strip()
                    if cid.isdigit() and int(cid) in categories_by_id:
                        cn.append(categories_by_id[int(cid)])
            cs = ", ".join(cn) if cn else "-"
            pdf.cell(28, 6, str(e["date"])[:10], border=1)
            pdf.cell(68, 6, str(e["description"])[:35], border=1)
            pdf.cell(38, 6, cs[:20], border=1)
            pdf.cell(34, 6, f"RD${float(e['amount']):,.2f}", border=1, align="R")
            pdf.ln()
        pdf.ln(3)

    if fixed_payments:
        _pdf_section(pdf, "Pagos Fijos")
        cols = [(70,"Nombre"),(28,"Fecha"),(34,"Monto")]
        _pdf_table_header(pdf, cols)
        for fp in fixed_payments:
            due_label = str(fp.get("due_date") or fp.get("due_day") or "-")
            pdf.cell(70, 6, str(fp["name"])[:35], border=1)
            pdf.cell(28, 6, due_label[:12], border=1)
            pdf.cell(34, 6, f"RD${float(fp['amount']):,.2f}", border=1, align="R")
            pdf.ln()
        pdf.ln(3)

    pending = [l for l in loans if not l.get("is_paid")]
    if pending:
        _pdf_section(pdf, "Prestamos Pendientes")
        cols = [(48,"Persona"),(58,"Descripcion"),(34,"Monto")]
        _pdf_table_header(pdf, cols)
        for ln_ in pending:
            pdf.cell(48, 6, str(ln_["person"])[:25], border=1)
            pdf.cell(58, 6, str(ln_.get("description",""))[:30], border=1)
            pdf.cell(34, 6, f"RD${float(ln_['amount']):,.2f}", border=1, align="R")
            pdf.ln()

    # Pie de pagina (sin forzar salto de pagina)
    pdf.set_auto_page_break(auto=False)
    pdf.set_y(-10)
    pdf.set_font("Helvetica", "I", 8)
    pdf.set_text_color(117, 117, 117)
    pdf.cell(0, 4, "RBP - Rivas Budget Planning | Generado automaticamente", align="C")

    pdf.output(str(output_path))
    logger.info(f"PDF: {output_path}")


# ───────────────────────── Servicio de datos ───────────────────────────
class FinanceService:
    def __init__(self, db: Database):
        self.db = db
        self.user_id = self._ensure_user()
        self._ensure_cats()

    def _ensure_user(self) -> int:
        users = self.db.get_all_users()
        if users: return int(users[0]["id"])
        ex = self.db.get_user_by_username("Jose")
        if ex: return int(ex["id"])
        return int(self.db.create_user("Jose","jose@example.com"))

    def _ensure_cats(self):
        if self.db.get_categories_by_user(self.user_id): return
        for n in DEFAULT_CATEGORIES:
            self.db.create_category(self.user_id, n)

    def get_categories(self) -> List[Dict]:
        return self.db.get_categories_by_user(self.user_id)

    def add_category(self, name: str):
        self.db.create_category(self.user_id, name.strip())

    def rename_category(self, category_id: int, new_name: str):
        self.db.update_category(category_id, name=new_name.strip())

    def delete_category(self, category_id: int):
        cursor = self.db.execute(
            "SELECT COUNT(*) FROM expense_categories WHERE category_id = ?",
            (category_id,),
        )
        used_in_expenses = int(cursor.fetchone()[0] or 0)
        cursor = self.db.execute(
            "SELECT COUNT(*) FROM fixed_payments WHERE category_id = ? AND is_active = 1",
            (category_id,),
        )
        used_in_fixed = int(cursor.fetchone()[0] or 0)
        if used_in_expenses > 0 or used_in_fixed > 0:
            raise ValueError("No se puede eliminar una categoría en uso.")
        self.db.delete_category(category_id)

    def add_expense(self, amount, description, category_id, date_text, source: str = "sueldo"):
        src = (source or "sueldo").strip().lower()
        status = "completed_savings" if src == "ahorro" else "completed_salary"
        d = datetime.strptime(date_text, "%Y-%m-%d").date()
        self.db.create_expense(self.user_id, amount, description.strip(),
                               date_text, self.get_cycle_for_date(d),
                               [category_id], status)

    def add_fixed_payment(self, name, amount, due_day, category_id):
        self.db.create_fixed_payment(self.user_id, name.strip(), amount,
                                     due_day, category_id)
    def delete_fixed_payment(self, pid): self.db.delete_fixed_payment(pid)

    def get_fixed_payments_for_period(self, year: int, month: int, cycle: int) -> List[Dict]:
        """Pagos fijos que caen dentro del rango visible, con fecha concreta."""
        base = self.db.get_fixed_payments_by_user(self.user_id)
        start_s, end_s = self.get_period_range(year, month, cycle)
        start_d = datetime.strptime(start_s, "%Y-%m-%d").date()
        end_d = datetime.strptime(end_s, "%Y-%m-%d").date()

        def _iter_months(y1: int, m1: int, y2: int, m2: int):
            y, m = y1, m1
            while (y < y2) or (y == y2 and m <= m2):
                yield y, m
                if m == 12:
                    y, m = y + 1, 1
                else:
                    m += 1

        out: List[Dict] = []
        for fp in base:
            due_day = int(fp.get("due_day") or 1)
            for y, m in _iter_months(start_d.year, start_d.month, end_d.year, end_d.month):
                last = monthrange(y, m)[1]
                day = min(max(1, due_day), last)
                due_dt = date(y, m, day)
                if start_d <= due_dt <= end_d:
                    item = dict(fp)
                    item["due_date"] = due_dt.isoformat()
                    out.append(item)
                    break
        out.sort(key=lambda x: x.get("due_date", ""))
        return out

    # ── ahorro ──
    def add_savings(self, amount):
        t = date.today()
        self.db.record_savings(self.user_id, amount, t.year, t.month,
                               self.get_cycle_for_date(t))
    def get_period_savings(self, year: int, month: int, cycle: int) -> float:
        row = self.db.get_savings_by_quincenal(self.user_id, year, month, cycle)
        if not row:
            return 0.0
        return float(row.get("last_quincenal_savings") or 0)
    def get_total_savings(self): return float(self.db.get_total_savings(self.user_id))
    def withdraw_savings(self, amount) -> bool:
        return self.db.withdraw_savings(self.user_id, amount)

    @staticmethod
    def _is_savings_expense(status: str) -> bool:
        st = (status or "").strip().lower()
        return st in ("completed_savings", "savings")

    # ── metas de ahorro ──
    def add_savings_goal(self, name, target):
        return self.db.create_savings_goal(self.user_id, name, target)
    def get_savings_goals(self):
        return self.db.get_savings_goals(self.user_id)
    def delete_savings_goal(self, gid):
        self.db.delete_savings_goal(gid)

    # ── salario ──
    def set_salary(self, amount): self.db.set_salary(self.user_id, amount)
    def get_salary(self): return self.db.get_salary(self.user_id)
    def set_salary_override(self, year, month, cycle, amount):
        self.db.set_salary_override(self.user_id, year, month, cycle, amount)
    def get_salary_override(self, year, month, cycle):
        return self.db.get_salary_override(self.user_id, year, month, cycle)
    def delete_salary_override(self, year, month, cycle):
        self.db.delete_salary_override(self.user_id, year, month, cycle)
    def get_salary_for_period(self, year, month, cycle):
        override = self.get_salary_override(year, month, cycle)
        if override is not None:
            return float(override)
        return self.get_salary()

    # ── modo de período ──
    def set_period_mode(self, mode: str):
        self.db.set_period_mode(self.user_id, mode)

    def get_period_mode(self) -> str:
        return self.db.get_period_mode(self.user_id)

    def set_setting(self, key: str, value: str):
        self.db.set_user_setting(self.user_id, key, value)

    def get_setting(self, key: str, default_value: str = "") -> str:
        return self.db.get_user_setting(self.user_id, key, default_value)

    @staticmethod
    def _next_month(y: int, m: int):
        return (y + 1, 1) if m == 12 else (y, m + 1)

    @staticmethod
    def _safe_day(y: int, m: int, day: int) -> int:
        _, last = monthrange(y, m)
        return min(max(1, int(day)), last)

    def _get_int_setting(self, key: str, default_value: int,
                         min_value: int = 1, max_value: int = 31) -> int:
        raw = self.get_setting(key, str(default_value))
        try:
            val = int(str(raw).strip())
        except Exception:
            val = int(default_value)
        return max(min_value, min(max_value, val))

    def get_quincenal_paydays(self):
        d1 = self._get_int_setting("quincenal_pay_day_1", 1)
        d2 = self._get_int_setting("quincenal_pay_day_2", 16)
        if d1 == d2:
            d2 = 16 if d1 != 16 else 15
        if d1 > d2:
            d1, d2 = d2, d1
        return d1, d2

    def get_monthly_payday(self) -> int:
        return self._get_int_setting("monthly_pay_day", 1)

    def get_period_start_days(self, y: int, m: int) -> List[int]:
        mode = self.get_period_mode()
        if mode == "mensual":
            return [self._safe_day(y, m, self.get_monthly_payday())]
        d1, d2 = self.get_quincenal_paydays()
        return sorted(set([
            self._safe_day(y, m, d1),
            self._safe_day(y, m, d2),
        ]))

    @staticmethod
    def get_month_range(y: int, m: int):
        _, last = monthrange(y, m)
        return f"{y}-{m:02d}-01", f"{y}-{m:02d}-{last}"

    def get_month_range_by_payday(self, y: int, m: int):
        pay_day = self._safe_day(y, m, self.get_monthly_payday())
        start = date(y, m, pay_day)
        ny, nm = self._next_month(y, m)
        next_pay_day = self._safe_day(ny, nm, self.get_monthly_payday())
        end = date(ny, nm, next_pay_day) - timedelta(days=1)
        return start.isoformat(), end.isoformat()

    def get_period_range(self, y: int, m: int, c: int):
        if self.get_period_mode() == "mensual":
            return self.get_month_range_by_payday(y, m)
        return self.get_quincena_range(y, m, c)

    def get_cycle_for_date(self, dt: date) -> int:
        if self.get_period_mode() == "mensual":
            return 1
        s1, e1 = self.get_quincena_range(dt.year, dt.month, 1)
        start_1 = datetime.strptime(s1, "%Y-%m-%d").date()
        end_1 = datetime.strptime(e1, "%Y-%m-%d").date()
        return 1 if start_1 <= dt <= end_1 else 2

    # ── ingresos extras ──
    def add_income(self, amount, desc, date_text):
        self.db.create_extra_income(self.user_id, amount, desc, date_text)
    def get_incomes(self, y, m, c):
        start_d, end_d = self.get_quincena_range(y, m, c)
        return self.db.get_extra_income_by_custom_range(self.user_id, start_d, end_d)
    def get_total_income(self, y, m, c):
        start_d, end_d = self.get_quincena_range(y, m, c)
        return self.db.get_total_extra_income_by_custom_range(self.user_id, start_d, end_d)
    def delete_income(self, iid): self.db.delete_extra_income(iid)

    # ── prestamos ──
    def add_loan(self, person, amount, description, date_text, deduction_type="ninguno"):
        self.db.create_loan(self.user_id, person, amount, description,
                            date_text, deduction_type)
    def get_loans(self, include_paid=False):
        return self.db.get_loans_by_user(self.user_id, include_paid)
    def mark_loan_paid(self, lid): self.db.mark_loan_paid(lid)
    def delete_loan(self, lid): self.db.delete_loan(lid)
    def get_total_unpaid_loans(self):
        return self.db.get_total_unpaid_loans(self.user_id)

    # ── edición ──
    def update_expense(self, eid, amount, description, date_text, category_id):
        self.db.update_expense(eid, amount=amount, description=description,
                               date=date_text, category_ids=[category_id])
    def update_fixed_payment(self, pid, name, amount, due_day, category_id):
        self.db.update_fixed_payment(pid, name=name, amount=amount,
                                     due_day=due_day, category_id=category_id)
    def update_loan(self, lid, person, amount, description, deduction_type):
        self.db.update_loan(lid, person=person, amount=amount,
                            description=description, deduction_type=deduction_type)
    def update_income(self, iid, amount, description, date_text):
        self.db.update_extra_income(iid, amount=amount, description=description,
                                    date=date_text)
    def update_savings_goal(self, gid, name, target):
        self.db.update_savings_goal(gid, name=name, target_amount=target)

    # ── quincena personalizada ──
    def set_custom_quincena(self, y, m, c, start, end):
        self.db.set_custom_quincena(self.user_id, y, m, c, start, end)
    def get_custom_quincena(self, y, m, c):
        return self.db.get_custom_quincena(self.user_id, y, m, c)
    def delete_custom_quincena(self, cq_id):
        self.db.delete_custom_quincena(cq_id)
    def get_quincena_range(self, y, m, c):
        """Retorna (start_date, end_date) — personalizado o estándar."""
        custom = self.db.get_custom_quincena_range(self.user_id, y, m, c)
        if custom:
            return custom
        d1, d2 = self.get_quincenal_paydays()
        d1 = self._safe_day(y, m, d1)
        d2 = self._safe_day(y, m, d2)

        if c == 1:
            start = date(y, m, d1)
            end = date(y, m, max(d1, d2 - 1))
            return start.isoformat(), end.isoformat()

        start = date(y, m, d2)
        ny, nm = self._next_month(y, m)
        next_d1 = self._safe_day(ny, nm, d1)
        end = date(ny, nm, next_d1) - timedelta(days=1)
        return start.isoformat(), end.isoformat()

    # ── dashboard ──
    def get_dashboard_data(self, year=None, month=None, cycle=None) -> Dict:
        t = date.today()
        if year is None:  year  = t.year
        if month is None: month = t.month
        if cycle is None:
            cycle = 1 if self.get_period_mode() == "mensual" else self.get_cycle_for_date(t)
        period_mode = self.get_period_mode()

        start_d, end_d = self.get_period_range(year, month, cycle)
        expenses      = self.db.get_expenses_by_custom_range(self.user_id, start_d, end_d)
        fixed_payments= self.get_fixed_payments_for_period(year, month, cycle)
        total_savings = self.get_total_savings()
        period_savings = self.get_period_savings(year, month, cycle)
        total_loans   = self.get_total_unpaid_loans()
        salary        = self.get_salary() if period_mode == "mensual" else self.get_salary_for_period(year, month, cycle)
        extra_income  = self.db.get_total_extra_income_by_custom_range(self.user_id, start_d, end_d)

        total_expenses = sum(float(e["amount"]) for e in expenses)
        total_expenses_salary = sum(
            float(e["amount"]) for e in expenses
            if not self._is_savings_expense(str(e.get("status") or ""))
        )
        total_expenses_savings = total_expenses - total_expenses_salary
        total_fixed    = sum(float(p["amount"]) for p in fixed_payments)

        dinero_inicial   = salary + extra_income - period_savings
        dinero_disponible= dinero_inicial - total_expenses_salary - total_fixed - total_loans

        # promedio diario
        daily: Dict[str,float] = defaultdict(float)
        for e in expenses: daily[str(e["date"])] += float(e["amount"])
        avg_daily = (sum(daily.values())/len(daily)) if daily else 0.0

        # gastos por categoria
        cat_totals: Dict[int,float] = defaultdict(float)
        for e in expenses:
            if e.get("category_ids"):
                for cid in str(e["category_ids"]).split(","):
                    cid = cid.strip()
                    if cid.isdigit(): cat_totals[int(cid)] += float(e["amount"])

        categories_by_id = {c["id"]:c["name"] for c in self.get_categories()}
        today_str = date.today().isoformat()
        formatted_recent = []
        for row in expenses[:12]:
            cn = []
            if row.get("category_ids"):
                for cid in str(row["category_ids"]).split(","):
                    cid = cid.strip()
                    if cid.isdigit() and int(cid) in categories_by_id:
                        cn.append(categories_by_id[int(cid)])
            formatted_recent.append({
                "date": row["date"], "description": row["description"],
                "amount": float(row["amount"]),
                "categories": ", ".join(cn) if cn else "Sin cat.",
                "type": "expense",
                "id": row["id"],
                "raw": row,
            })

        # Agregar vencimientos de pagos fijos cuando llegue su fecha
        for fp in fixed_payments:
            due_date = str(fp.get("due_date") or "")
            if due_date and due_date <= today_str:
                formatted_recent.append({
                    "date": due_date,
                    "description": f'Pago fijo: {fp.get("name", "(sin nombre)")}',
                    "amount": float(fp.get("amount") or 0),
                    "categories": "Pago fijo",
                    "type": "fixed_due",
                    "id": fp.get("id"),
                    "raw": fp,
                })

        formatted_recent.sort(key=lambda x: str(x.get("date", "")), reverse=True)
        formatted_recent = formatted_recent[:20]

        return {
            "year":year, "month":month, "cycle":cycle,
            "period_mode": period_mode,
            "salary":salary, "extra_income":extra_income,
            "dinero_inicial":dinero_inicial,
            "total_expenses":total_expenses,
            "total_fixed":total_fixed, "total_loans":total_loans,
            "period_savings":period_savings,
            "total_savings":total_savings,
            "total_expenses_salary":total_expenses_salary,
            "total_expenses_savings":total_expenses_savings,
            "dinero_disponible":dinero_disponible,
            "avg_daily":avg_daily,
            "expense_count":len(expenses), "fixed_count":len(fixed_payments),
            "recent_expenses":formatted_recent,
            "fixed_payments":fixed_payments,
            "raw_expenses":expenses,
            "categories_by_id":categories_by_id,
            "cat_totals":cat_totals,
            "quincena_range": (start_d, end_d),
        }

    def generate_report(self, y, m, c) -> Path:
        data = self.get_dashboard_data(y, m, c)
        loans = self.get_loans(include_paid=True)
        mode = data.get("period_mode", "quincenal")
        ms = {1:"Ene",2:"Feb",3:"Mar",4:"Abr",5:"May",6:"Jun",
              7:"Jul",8:"Ago",9:"Sep",10:"Oct",11:"Nov",12:"Dic"}
        if mode == "mensual":
            start_d, end_d = data.get("quincena_range", ("", ""))
            label = f"Mensual {ms[m]} {y} ({start_d} a {end_d})"
            out = REPORTS_DIR / f"reporte_{y}_{m:02d}_M.pdf"
            title = "RBP - Reporte Mensual"
        else:
            label = _qlabel(y, m, c)
            out = REPORTS_DIR / f"reporte_{y}_{m:02d}_Q{c}.pdf"
            title = "RBP - Reporte Quincenal"
        generate_pdf_report(
            title=title, period_label=label,
            expenses=data["raw_expenses"], fixed_payments=data["fixed_payments"],
            loans=loans, total_savings=data["total_savings"],
            salary=data["salary"], extra_income=data["extra_income"],
            categories_by_id=data["categories_by_id"], output_path=out,
            icon_path=_ICON_PATH,
        )
        return out

    def export_csv(self, y, m, c) -> Path:
        data = self.get_dashboard_data(y, m, c)
        mode = data.get("period_mode", "quincenal")
        suffix = "M" if mode == "mensual" else f"Q{c}"
        out = REPORTS_DIR / f"gastos_{y}_{m:02d}_{suffix}.csv"
        with open(out, "w", newline="", encoding="utf-8-sig") as f:
            w = csv.writer(f)
            w.writerow(["Fecha","Descripcion","Categoria","Monto"])
            for e in data["raw_expenses"]:
                cn = []
                if e.get("category_ids"):
                    for cid in str(e["category_ids"]).split(","):
                        cid = cid.strip()
                        if cid.isdigit() and int(cid) in data["categories_by_id"]:
                            cn.append(data["categories_by_id"][int(cid)])
                w.writerow([e["date"], e["description"],
                            ", ".join(cn) or "-", float(e["amount"])])
        return out


# ───────────────────────── App Flet ────────────────────────────────────
class FinanzasFletApp:
    def __init__(self):
        self.db = Database(DB_PATH)
        self.service = FinanceService(self.db)
        self.backup_manager = BackupManager(DB_PATH, BACKUP_DIR)
        self.page: Optional[ft.Page] = None
        self._skip_startup_checks = False

        # quincena visible en el dashboard
        t = date.today()
        self._vy, self._vm, self._vc = t.year, t.month, self.service.get_cycle_for_date(t)

        # dashboard widgets
        self.lbl_dinero_ini  = ft.Text("RD$0.00", size=20, weight=ft.FontWeight.BOLD)
        self.lbl_total_gasto = ft.Text("RD$0.00", size=20, weight=ft.FontWeight.BOLD, color=_ERROR)
        self.lbl_ahorro_tot  = ft.Text("RD$0.00", size=20, weight=ft.FontWeight.BOLD, color=_SUCCESS)
        self.lbl_dinero_disp = ft.Text("RD$0.00", size=20, weight=ft.FontWeight.BOLD)
        self.lbl_avg_daily   = ft.Text("RD$0.00", size=20, weight=ft.FontWeight.BOLD)
        self.lbl_loans       = ft.Text("RD$0.00", size=20, weight=ft.FontWeight.BOLD, color=_WARN)
        self.quincenal_label = ft.Text("", size=14, weight=ft.FontWeight.W_500, color=_PRIMARY)
        self.recent_list     = ft.ListView(spacing=4, expand=True)
        self.chart_container = ft.Container()
        self.lbl_period_savings_current = ft.Text("Actual: RD$0.00", size=12, color=_SUBTITLE)
        self.lbl_total_savings_available = ft.Text("Disponible: RD$0.00", size=12, color=_SUBTITLE)

        # listas
        self.fixed_list   = ft.ListView(spacing=4, expand=True)
        self.loans_list   = ft.ListView(spacing=4, expand=True)
        self.income_list  = ft.ListView(spacing=4, expand=True)
        self.goals_list   = ft.ListView(spacing=4, expand=True)

    # ── helpers ──
    def _snack(self, msg, error=False):
        if not self.page: return
        txt = (msg or "").strip()
        key = txt.lower()

        required_msgs = {
            "completa campos.",
            "completa todo.",
            "ingresa salario.",
            "ingresa monto.",
            "completa persona y monto.",
            "completa ambas fechas.",
        }
        invalid_msgs = {
            "invalido.",
            "inválido.",
            "monto invalido.",
            "monto inválido.",
            "fecha invalida.",
            "fecha inválida.",
            "formato de fecha inválido.",
        }

        if error and key in required_msgs:
            txt = "Favor llenar los campos requeridos."
        elif error and key in invalid_msgs:
            txt = "Hay datos inválidos. Verifica los campos e intenta de nuevo."

        sb = ft.SnackBar(
            content=ft.Text(txt, color="white"),
            bgcolor=_ERROR if error else _SUCCESS,
        )
        try:
            self.page.open(sb)
        except Exception:
            sb.open = True
            self.page.snack_bar = sb
            self.page.update()

    def _get_bool_setting(self, key: str, default: bool = False) -> bool:
        raw = self.service.get_setting(key, "1" if default else "0")
        return str(raw).strip().lower() in ("1", "true", "yes", "si", "sí", "on")

    def _set_bool_setting(self, key: str, value: bool):
        self.service.set_setting(key, "1" if value else "0")

    @staticmethod
    def _version_tuple(v: str):
        s = (v or "").strip().lower()
        if s.startswith("v"):
            s = s[1:]
        m = re.match(r"^(\d+)\.(\d+)\.(\d+)(?:[-.]?(alpha|beta|rc)[.-]?(\d+)?)?", s)
        if m:
            major = int(m.group(1))
            minor = int(m.group(2))
            patch = int(m.group(3))
            pre = (m.group(4) or "").lower()
            pre_num = int(m.group(5) or 0)
            pre_rank = {"alpha": 0, "beta": 1, "rc": 2}.get(pre, 3)
            return (major, minor, patch, pre_rank, pre_num)

        s = re.sub(r"[^0-9.]", "", s)
        parts = [int(p) for p in s.split(".") if p.isdigit()]
        while len(parts) < 3:
            parts.append(0)
        return (parts[0], parts[1], parts[2], 3, 0)

    def _is_newer_version(self, latest_tag: str) -> bool:
        return self._version_tuple(latest_tag) > self._version_tuple(APP_VERSION)

    def _release_payload_to_info(self, payload: Dict) -> Dict:
        asset_url = ""
        asset_name = ""
        assets = payload.get("assets") or []
        if isinstance(assets, list):
            preferred = None
            for a in assets:
                if not isinstance(a, dict):
                    continue
                name = str(a.get("name") or "")
                if name.lower().endswith(".zip") and "portable" in name.lower():
                    preferred = a
                    break
            if not preferred:
                for a in assets:
                    if not isinstance(a, dict):
                        continue
                    name = str(a.get("name") or "")
                    if name.lower().endswith(".zip"):
                        preferred = a
                        break
            if preferred:
                asset_url = str(preferred.get("browser_download_url") or "").strip()
                asset_name = str(preferred.get("name") or "").strip()

        return {
            "tag": str(payload.get("tag_name") or "").strip(),
            "url": str(payload.get("html_url") or "").strip(),
            "notes": str(payload.get("body") or "").strip(),
            "prerelease": bool(payload.get("prerelease", False)),
            "asset_url": asset_url,
            "asset_name": asset_name,
        }

    @staticmethod
    def _safe_tag_name(tag: str) -> str:
        raw = (tag or "").strip().replace(" ", "_")
        return re.sub(r"[^a-zA-Z0-9._-]", "_", raw)

    def _download_and_prepare_update(self, latest: Dict) -> bool:
        tag = str(latest.get("tag") or "").strip()
        asset_url = str(latest.get("asset_url") or "").strip()
        asset_name = str(latest.get("asset_name") or "update.zip").strip() or "update.zip"

        if not tag or not asset_url:
            self._snack("No se encontró archivo instalable en la release.", error=True)
            return False

        updates_root = BASE_DIR.parent / "RBP_updates"
        updates_root.mkdir(parents=True, exist_ok=True)

        tag_safe = self._safe_tag_name(tag)
        zip_path = updates_root / f"{tag_safe}.zip"
        target_dir = updates_root / f"RBP_{tag_safe}"

        self._snack("Descargando actualización...")
        try:
            req = urlrequest.Request(asset_url, headers={"User-Agent": f"RBP/{APP_VERSION}"})
            with urlrequest.urlopen(req, timeout=30) as resp, open(zip_path, "wb") as f:
                while True:
                    chunk = resp.read(1024 * 256)
                    if not chunk:
                        break
                    f.write(chunk)
        except Exception:
            logger.exception("update_download")
            self._snack("Falló la descarga automática. Se abrirá GitHub.", error=True)
            return False

        self._snack("Preparando actualización...")
        try:
            if target_dir.exists():
                shutil.rmtree(target_dir, ignore_errors=True)
            target_dir.mkdir(parents=True, exist_ok=True)
            with zipfile.ZipFile(zip_path, "r") as zf:
                zf.extractall(target_dir)

            # Migrar datos del usuario automáticamente
            for folder_name in ("data", "backups"):
                src_dir = BASE_DIR / folder_name
                dst_dir = target_dir / folder_name
                if src_dir.exists() and src_dir.is_dir():
                    shutil.copytree(src_dir, dst_dir, dirs_exist_ok=True)

            exe_candidates = [
                target_dir / "RBP.exe",
                target_dir / "RBP" / "RBP.exe",
            ]
            exe_path = None
            for cand in exe_candidates:
                if cand.exists():
                    exe_path = cand
                    break
            if exe_path is None:
                found = list(target_dir.rglob("RBP.exe"))
                if found:
                    exe_path = found[0]

            if exe_path and exe_path.exists():
                try:
                    if os.name == "nt":
                        os.startfile(str(exe_path))
                    else:
                        webbrowser.open(str(exe_path))
                except Exception:
                    logger.exception("update_launch")
                self._snack(f"Actualización {tag} lista. Se abrió la nueva app.")
            else:
                self._snack(f"Actualización {tag} lista en: {target_dir}")
            return True
        except Exception:
            logger.exception("update_prepare")
            self._snack("No se pudo preparar la actualización automática.", error=True)
            return False

    def _fetch_latest_release(self, include_beta: bool = False) -> Optional[Dict]:
        url = GITHUB_RELEASES_API if include_beta else GITHUB_RELEASE_LATEST_API
        req = urlrequest.Request(
            url,
            headers={"User-Agent": f"RBP/{APP_VERSION}"},
        )
        try:
            with urlrequest.urlopen(req, timeout=8) as resp:
                payload = json.loads(resp.read().decode("utf-8", errors="ignore"))
                if not include_beta:
                    return self._release_payload_to_info(payload)

                if not isinstance(payload, list):
                    return None

                for rel in payload:
                    if not isinstance(rel, dict):
                        continue
                    if bool(rel.get("draft", False)):
                        continue
                    return self._release_payload_to_info(rel)
                return None
        except urlerror.URLError:
            return None
        except Exception:
            logger.exception("update_fetch")
            return None

    def _open_update_dialog(self, latest: Dict, manual: bool = False):
        if not self.page:
            return
        tag = latest.get("tag", "")
        url = latest.get("url", "")
        notes = latest.get("notes", "")
        notes_preview = (notes[:300] + "...") if len(notes) > 300 else notes

        def on_download(_):
            ok_auto = self._download_and_prepare_update(latest)
            if ok_auto:
                dlg.open = False
                self.page.update()
                return
            try:
                if os.name == "nt" and url:
                    os.startfile(url)
                elif url:
                    webbrowser.open(url)
            except Exception:
                logger.exception("open_update_url")
            dlg.open = False
            self.page.update()
            self._snack("Se abrió la descarga de la nueva versión.")

        def on_later(_):
            self.service.set_setting("update_snoozed_version", tag)
            dlg.open = False
            self.page.update()
            self._snack("Te lo recordaré luego.")

        def on_close(_):
            dlg.open = False
            self.page.update()

        actions = [
            ft.TextButton("Cerrar", on_click=on_close),
            ft.OutlinedButton("Recordármelo luego", on_click=on_later),
            ft.FilledButton("Descargar", icon=ft.Icons.DOWNLOAD, on_click=on_download,
                            style=ft.ButtonStyle(bgcolor=_PRIMARY)),
        ]
        if manual:
            actions = [
                ft.TextButton("Cerrar", on_click=on_close),
                ft.FilledButton("Descargar", icon=ft.Icons.DOWNLOAD, on_click=on_download,
                                style=ft.ButtonStyle(bgcolor=_PRIMARY)),
            ]

        dlg = ft.AlertDialog(
            title=ft.Text("Actualización disponible", weight=ft.FontWeight.BOLD, color=_PRIMARY),
            content=ft.Container(
                width=420,
                content=ft.Column([
                    ft.Text(f"Versión actual: v{APP_VERSION}"),
                    ft.Text(f"Nueva versión: {tag}", weight=ft.FontWeight.W_600),
                    ft.Container(height=6),
                    ft.Text("Novedades:", size=12, color=_SUBTITLE),
                    ft.Text(notes_preview or "Sin notas de versión.", size=12),
                ], spacing=6, tight=True),
            ),
            actions=actions,
            actions_alignment=ft.MainAxisAlignment.END,
        )
        self.page.overlay.append(dlg)
        dlg.open = True
        self.page.update()

    def _check_for_updates(self, manual: bool = False, include_beta: Optional[bool] = None):
        if include_beta is None:
            include_beta = self._get_bool_setting("include_beta_updates", False)

        today_key = date.today().isoformat()
        check_key = "update_last_check_date_beta" if include_beta else "update_last_check_date_stable"
        if not manual:
            last_check = self.service.get_setting(check_key, "")
            if last_check == today_key:
                return

        latest = self._fetch_latest_release(include_beta=bool(include_beta))
        self.service.set_setting(check_key, today_key)

        if not latest or not latest.get("tag"):
            if manual:
                self._snack("No se pudo verificar actualizaciones ahora mismo.", error=True)
            return

        latest_tag = latest["tag"]
        self.service.set_setting("update_last_seen_version", latest_tag)
        is_new = self._is_newer_version(latest_tag)

        if not is_new:
            if manual:
                if include_beta:
                    self._snack("Ya tienes la versión más reciente (incluyendo beta).")
                else:
                    self._snack("Ya tienes la versión más reciente.")
            return

        if not manual:
            snoozed = self.service.get_setting("update_snoozed_version", "")
            if snoozed == latest_tag:
                return

        self._open_update_dialog(latest, manual=manual)

    def _reload_ui(self):
        if not self.page:
            return
        self._skip_startup_checks = True
        self.page.clean()
        self.main(self.page)

    def _create_backup(self):
        if self.backup_manager.create_backup():
            self._snack("Respaldo creado correctamente.")
        else:
            self._snack("No se pudo crear el respaldo.", error=True)

    def _restore_latest_backup(self):
        latest = self.backup_manager.get_latest_backup()
        if not latest:
            self._snack("No hay respaldos disponibles.", error=True)
            return
        try:
            self.db.disconnect()
        except Exception:
            pass
        if not self.backup_manager.restore_backup(latest):
            self._snack("No se pudo restaurar el respaldo.", error=True)
            return
        self.db = Database(DB_PATH)
        self.service = FinanceService(self.db)
        self._refresh_all()
        self._snack(f"Respaldo restaurado: {latest.name}")

    @staticmethod
    def _vdate(t):
        try: datetime.strptime(t,"%Y-%m-%d"); return True
        except ValueError: return False

    def _cat_opts(self):
        return [ft.dropdown.Option(str(c["id"]),c["name"])
                for c in self.service.get_categories()]
    
    def _open_date_picker(self, target_field: ft.TextField):
        if not self.page:
            return
        initial = date.today()
        try:
            if target_field.value:
                initial = datetime.strptime(target_field.value, "%Y-%m-%d").date()
        except Exception:
            pass

        def _on_change(e: ft.ControlEvent):
            picked = e.control.value
            if picked:
                if isinstance(picked, datetime):
                    picked = picked.date()
                target_field.value = picked.strftime("%Y-%m-%d")
                self.page.update()

        picker = ft.DatePicker(
            first_date=date(2000, 1, 1),
            last_date=date(2100, 12, 31),
            value=initial,
            on_change=_on_change,
        )
        try:
            self.page.open(picker)
        except Exception:
            self.page.overlay.append(picker)
            picker.open = True
            self.page.update()

    def _date_field_row(self, field: ft.TextField) -> ft.Row:
        return ft.Row([
            field,
            ft.IconButton(
                ft.Icons.CALENDAR_MONTH,
                tooltip="Elegir fecha",
                icon_color=_PRIMARY,
                on_click=lambda _: self._open_date_picker(field),
            ),
        ], spacing=6)

    @staticmethod
    def _card(title, icon, widget, col=None):
        if col is None: col={"xs":12,"sm":6,"md":4}
        return ft.Container(
            padding=16, border_radius=14, bgcolor=_CARD_BG,
            border=ft.border.all(1,_CARD_BD), col=col,
            content=ft.Column([
                ft.Row([ft.Icon(icon,color=_PRIMARY,size=18),
                        ft.Text(title,size=12,color=_SUBTITLE)]),
                widget], spacing=6))

    # ── pie chart (canvas) ──
    def _build_pie(self, cat_totals: Dict[int,float], cats_by_id: Dict[int,str]):
        if not cat_totals:
            return ft.Text("Sin gastos para graficar", italic=True, color=_SUBTITLE)
        total = sum(cat_totals.values())
        sections = []
        legend_items = []
        idx = 0
        for cid, amt in sorted(cat_totals.items(), key=lambda x:-x[1]):
            pct = amt / total * 100 if total else 0
            name = cats_by_id.get(cid, "?")
            color = _PIE_COLORS[idx % len(_PIE_COLORS)]
            sections.append(ft.PieChartSection(
                value=amt,
                color=color, radius=80))
            legend_items.append(
                ft.Row([
                    ft.Container(width=12, height=12, bgcolor=color, border_radius=2),
                    ft.Text(f"{name}: {pct:.1f}% ({format_currency(amt)})", size=12,
                            color="#263238"),
                ], spacing=8)
            )
            idx += 1
        chart = ft.PieChart(
            sections=sections,
            sections_space=3,
            center_space_radius=42,
            width=420,
            height=420,
        )
        return ft.ResponsiveRow([
            ft.Container(col={"xs":12,"md":7}, alignment=ft.alignment.center,
                         content=chart),
            ft.Container(
                col={"xs":12,"md":5},
                padding=ft.padding.only(left=8, top=8),
                content=ft.Column(
                    [ft.Text("Leyenda", size=14, weight=ft.FontWeight.BOLD, color=_PRIMARY),
                     *legend_items],
                    spacing=8,
                    scroll=ft.ScrollMode.AUTO,
                ),
            ),
        ], run_spacing=10)

    def _qlabel_smart(self, data):
        """Etiqueta de quincena que muestra rango real (personalizado o estándar)."""
        y, m, c = data["year"], data["month"], data["cycle"]
        mode = data.get("period_mode", "quincenal")
        ms = {1:"Ene",2:"Feb",3:"Mar",4:"Abr",5:"May",6:"Jun",
              7:"Jul",8:"Ago",9:"Sep",10:"Oct",11:"Nov",12:"Dic"}
        start_d, end_d = data.get("quincena_range", ("",""))
        if mode == "mensual":
            if start_d and end_d:
                try:
                    sd = int(start_d.split("-")[2])
                    ed = int(end_d.split("-")[2])
                    return f"{sd}-{ed} {ms[m]} {y}  (Mensual)"
                except Exception:
                    pass
            return f"01-{monthrange(y,m)[1]} {ms[m]} {y}  (Mensual)"
        if start_d and end_d:
            # Extraer dia de start y end
            try:
                sd = int(start_d.split("-")[2])
                ed = int(end_d.split("-")[2])
                return f"{sd}-{ed} {ms[m]} {y}  (Q{c})"
            except Exception:
                pass
        rng = "1-15" if c == 1 else f"16-{monthrange(y,m)[1]}"
        return f"{rng} {ms[m]} {y}  (Q{c})"

    def _open_custom_quincena_dialog(self):
        """Diálogo para configurar fechas personalizadas de la quincena actual."""
        if self.service.get_period_mode() == "mensual":
            self._snack("En modo mensual no aplica calendario de quincena.", error=True)
            return
        y, m, c = self._vy, self._vm, self._vc
        start_d, end_d = self.service.get_quincena_range(y, m, c)

        sf = ft.TextField(label="Fecha inicio", value=start_d, width=260)
        ef = ft.TextField(label="Fecha fin", value=end_d, width=260)
        sf_row = self._date_field_row(sf)
        ef_row = self._date_field_row(ef)

        # Mostrar info
        ms = {1:"Ene",2:"Feb",3:"Mar",4:"Abr",5:"May",6:"Jun",
              7:"Jul",8:"Ago",9:"Sep",10:"Oct",11:"Nov",12:"Dic"}
        info = ft.Text(f"Quincena: Q{c} {ms[m]} {y}", size=14,
                       weight=ft.FontWeight.W_500, color=_PRIMARY)

        # Verificar si tiene personalización
        cq = self.service.get_custom_quincena(y, m, c)
        status = ft.Text("Rango personalizado activo ✓" if cq else "Usando rango estándar",
                         size=12, color=_SUCCESS if cq else _SUBTITLE)

        def on_save(_):
            s = (sf.value or "").strip(); e = (ef.value or "").strip()
            if not s or not e:
                self._snack("Completa ambas fechas.", error=True); return
            if not self._vdate(s) or not self._vdate(e):
                self._snack("Formato de fecha inválido.", error=True); return
            self.service.set_custom_quincena(y, m, c, s, e)
            dlg.open = False
            self._refresh_all()
            self._snack(f"Quincena Q{c} {ms[m]} {y} personalizada: {s} → {e}")

        def on_reset(_):
            if cq:
                self.service.delete_custom_quincena(cq["id"])
                dlg.open = False
                self._refresh_all()
                self._snack("Quincena restablecida a rango estándar.")
            else:
                self._snack("Ya usa el rango estándar.", error=True)

        def on_close(_):
            dlg.open = False
            self.page.update()

        dlg = ft.AlertDialog(
            title=ft.Text("Calendario de quincena", weight=ft.FontWeight.BOLD, color=_PRIMARY),
            content=ft.Column([
                info, status,
                ft.Container(height=4),
                ft.Text("Ajusta las fechas si la quincena empezó/terminó en un día diferente "
                         "(ej: por fin de semana o feriado).", size=12, color=_SUBTITLE),
                ft.Container(height=8),
                sf_row, ef_row,
            ], spacing=8, tight=True, width=340),
            actions=[
                ft.TextButton("Cerrar", on_click=on_close),
                ft.OutlinedButton("Restablecer", icon=ft.Icons.RESTORE,
                                  on_click=on_reset),
                ft.FilledButton("Guardar", icon=ft.Icons.SAVE, on_click=on_save,
                                style=ft.ButtonStyle(bgcolor=_PRIMARY)),
            ],
            actions_alignment=ft.MainAxisAlignment.END)
        self.page.overlay.append(dlg)
        dlg.open = True
        self.page.update()

    # ═══════════════════════ TABS ═══════════════════════

    def _build_dashboard_tab(self) -> ft.Tab:
        row1 = ft.ResponsiveRow([
            self._card("Dinero Inicial", ft.Icons.ACCOUNT_BALANCE_WALLET, self.lbl_dinero_ini),
            self._card("Total Gastado",  ft.Icons.SHOPPING_CART, self.lbl_total_gasto),
            self._card("Ahorro Total",   ft.Icons.SAVINGS, self.lbl_ahorro_tot),
        ], spacing=10, run_spacing=10)
        row2 = ft.ResponsiveRow([
            self._card("Dinero Disponible", ft.Icons.CHECK_CIRCLE, self.lbl_dinero_disp),
            self._card("Promedio Diario",   ft.Icons.CALENDAR_VIEW_DAY, self.lbl_avg_daily),
            self._card("Prestamos Pend.",   ft.Icons.MONEY_OFF, self.lbl_loans),
        ], spacing=10, run_spacing=10)

        def on_prev(_):
            if self.service.get_period_mode() == "mensual":
                if self._vm == 1:
                    self._vy, self._vm = self._vy - 1, 12
                else:
                    self._vm -= 1
                self._vc = 1
            else:
                self._vy, self._vm, self._vc = _prev_q(self._vy,self._vm,self._vc)
            self._refresh_all()
        def on_next(_):
            if self.service.get_period_mode() == "mensual":
                if self._vm == 12:
                    self._vy, self._vm = self._vy + 1, 1
                else:
                    self._vm += 1
                self._vc = 1
            else:
                self._vy, self._vm, self._vc = _next_q(self._vy,self._vm,self._vc)
            self._refresh_all()
        def on_today(_):
            t=date.today()
            self._vy, self._vm = t.year, t.month
            self._vc = 1 if self.service.get_period_mode() == "mensual" else self.service.get_cycle_for_date(t)
            self._refresh_all()

        def on_pdf(_):
            try:
                p=self.service.generate_report(self._vy,self._vm,self._vc)
                self._snack(f"PDF: {p.name}")
                try: os.startfile(str(p))
                except: pass
            except Exception:
                logger.exception("pdf"); self._snack("Error al generar PDF.",error=True)

        def on_csv(_):
            try:
                p=self.service.export_csv(self._vy,self._vm,self._vc)
                self._snack(f"CSV: {p.name}")
                try: os.startfile(str(p))
                except: pass
            except Exception:
                logger.exception("csv"); self._snack("Error al exportar CSV.",error=True)

        def on_chart(_):
            """Abrir gráfico de categorías en un AlertDialog."""
            chart_widget = self.chart_container.content
            if chart_widget is None:
                chart_widget = ft.Text("Sin gastos para graficar", italic=True, color=_SUBTITLE)
            # Clonar el PieChart para el diálogo
            try:
                data = self.service.get_dashboard_data(self._vy, self._vm, self._vc)
                chart_widget = self._build_pie(data["cat_totals"], data["categories_by_id"])
            except Exception:
                chart_widget = ft.Text("Error al cargar gráfico", color=_ERROR)
            def close_dlg(_):
                dlg.open = False
                self.page.update()
            dlg = ft.AlertDialog(
                title=ft.Text("Gastos por categoría", weight=ft.FontWeight.BOLD, color=_PRIMARY),
                content=ft.Container(
                    width=820, height=520, alignment=ft.alignment.center,
                    content=chart_widget),
                actions=[ft.TextButton("Cerrar", on_click=close_dlg)],
                actions_alignment=ft.MainAxisAlignment.END)
            self.page.overlay.append(dlg)
            dlg.open = True
            self.page.update()

        def on_calendar(_):
            self._open_custom_quincena_dialog()

        period_mode = self.service.get_period_mode()
        prev_tip = "Mes anterior" if period_mode == "mensual" else "Quincena anterior"
        next_tip = "Mes siguiente" if period_mode == "mensual" else "Quincena siguiente"

        nav_row = ft.Row([
            ft.IconButton(ft.Icons.CHEVRON_LEFT, on_click=on_prev, tooltip=prev_tip),
            self.quincenal_label,
            ft.IconButton(ft.Icons.CHEVRON_RIGHT, on_click=on_next, tooltip=next_tip),
            ft.TextButton("Hoy", on_click=on_today),
            ft.Container(expand=True),
            ft.IconButton(ft.Icons.CALENDAR_MONTH, on_click=on_calendar,
                          tooltip="Ajustar fechas de quincena" if period_mode == "quincenal" else "Modo mensual",
                          icon_color=_PRIMARY),
            ft.OutlinedButton("Gráfico", icon=ft.Icons.PIE_CHART, on_click=on_chart),
            ft.OutlinedButton("PDF", icon=ft.Icons.PICTURE_AS_PDF, on_click=on_pdf),
            ft.OutlinedButton("CSV", icon=ft.Icons.TABLE_CHART, on_click=on_csv),
        ])

        return ft.Tab(
            text="Resumen", icon=ft.Icons.DASHBOARD,
            content=ft.Container(
                expand=True,
                padding=ft.padding.only(top=12),
                content=ft.Column([
                    nav_row, row1, row2,
                    ft.Container(height=4),
                    ft.Text("Ultimos gastos", size=15, weight=ft.FontWeight.W_600),
                    ft.Container(expand=True, border_radius=12, border=ft.border.all(1,_CARD_BD),
                                 bgcolor=_CARD_BG, padding=8, content=self.recent_list),
                ], spacing=8, expand=True)))

    def _build_income_tab(self) -> ft.Tab:
        period_mode = self.service.get_period_mode()
        base_salary = self.service.get_salary()
        current_override = self.service.get_salary_override(self._vy, self._vm, self._vc)
        mode_label = "mensual" if period_mode == "mensual" else "quincenal"

        sal_f = ft.TextField(label=f"Salario base {mode_label} RD$", hint_text="25000",
                             keyboard_type=ft.KeyboardType.NUMBER, width=260,
                             value=str(base_salary) if base_salary else "")
        sal_q_f = ft.TextField(
            label=f"Salario esta quincena (Q{self._vc} {self._vm:02d}/{self._vy}) RD$",
            hint_text="Opcional: monto solo para esta quincena",
            keyboard_type=ft.KeyboardType.NUMBER,
            width=320,
            value=str(current_override) if current_override is not None else "",
        )
        ia = ft.TextField(label="Monto RD$", hint_text="5000",
                          keyboard_type=ft.KeyboardType.NUMBER, width=200)
        id_ = ft.TextField(label="Descripcion", hint_text="Freelance", width=300)
        idt = ft.TextField(label="Fecha", value=date.today().strftime("%Y-%m-%d"), width=180)
        idt_row = self._date_field_row(idt)

        def on_sal(_):
            s=(sal_f.value or "").strip()
            if not s: self._snack("Ingresa salario.",error=True); return
            try:
                v=float(s)
                if v<0: raise ValueError
            except ValueError: self._snack("Invalido.",error=True); return
            self.service.set_salary(v); self._refresh_all()
            self._snack("Salario base guardado correctamente.")

        def on_sal_quincena(_):
            if period_mode == "mensual":
                self._snack("En modo mensual no aplica salario por quincena.", error=True); return
            s = (sal_q_f.value or "").strip()
            if not s:
                self._snack("Ingresa monto.", error=True); return
            try:
                v = float(s)
                if v < 0:
                    raise ValueError
            except ValueError:
                self._snack("Invalido.", error=True); return
            self.service.set_salary_override(self._vy, self._vm, self._vc, v)
            self._refresh_all()
            self._snack(f"Salario de quincena guardado (Q{self._vc} {self._vm:02d}/{self._vy}).")

        def on_reset_sal_quincena(_):
            if period_mode == "mensual":
                self._snack("En modo mensual no aplica salario por quincena.", error=True); return
            self.service.delete_salary_override(self._vy, self._vm, self._vc)
            sal_q_f.value = ""
            self._refresh_all()
            self._snack("Salario de quincena restablecido al salario base.")

        def on_inc(_):
            a=(ia.value or "").strip(); d=(id_.value or "").strip()
            dt=(idt.value or "").strip()
            if not a or not d: self._snack("Completa campos.",error=True); return
            try:
                v=float(a)
                if v<=0: raise ValueError
            except ValueError: self._snack("Monto invalido.",error=True); return
            if dt and not self._vdate(dt): self._snack("Fecha invalida.",error=True); return
            if not dt: dt=date.today().strftime("%Y-%m-%d")
            self.service.add_income(v,d,dt)
            ia.value=""; id_.value=""; idt.value=date.today().strftime("%Y-%m-%d")
            self._refresh_all(); self._snack("Ingreso registrado.")

        salary_panel = ft.Container(
            col={"xs": 12, "md": 7},
            content=ft.Column([
                ft.Text("Salario",size=18,weight=ft.FontWeight.W_600),
                ft.Row([sal_f,
                        ft.FilledButton("Guardar",icon=ft.Icons.SAVE,
                                        on_click=on_sal,
                                        style=ft.ButtonStyle(bgcolor=_PRIMARY))],spacing=10, wrap=True),
                ft.Text("Salario variable por quincena", size=14, color=_SUBTITLE),
                ft.Row([
                    sal_q_f,
                    ft.FilledButton(
                        "Guardar quincena",
                        icon=ft.Icons.EVENT_AVAILABLE,
                        on_click=on_sal_quincena,
                        style=ft.ButtonStyle(bgcolor=_PRIMARY),
                        disabled=period_mode == "mensual",
                    ),
                    ft.OutlinedButton(
                        "Usar base",
                        icon=ft.Icons.RESTART_ALT,
                        on_click=on_reset_sal_quincena,
                        disabled=period_mode == "mensual",
                    ),
                ], spacing=10, wrap=True),
                ft.Text(
                    "En modo mensual se usa solo el salario base del mes."
                    if period_mode == "mensual" else
                    "En modo quincenal puedes ajustar montos por quincena.",
                    size=12,
                    color=_SUBTITLE,
                ),
            ], spacing=8),
        )

        add_income_panel = ft.Container(
            col={"xs": 12, "md": 5},
            content=ft.Column([
                ft.Text("Agregar ingreso",size=16,weight=ft.FontWeight.W_600),
                ia, id_, idt_row,
                ft.Container(height=4),
                ft.FilledButton("Agregar",icon=ft.Icons.ADD,on_click=on_inc,
                                style=ft.ButtonStyle(bgcolor=_SUCCESS)),
            ], spacing=8),
        )

        return ft.Tab(text="Ingresos", icon=ft.Icons.ATTACH_MONEY,
            content=ft.Container(expand=True, padding=ft.padding.only(top=16,left=8),
                content=ft.Column([
                    ft.ResponsiveRow([salary_panel, add_income_panel], spacing=12, run_spacing=12),
                    ft.Divider(),
                    ft.Text("Ingresos extras",size=16,weight=ft.FontWeight.W_600),
                    ft.Container(expand=True, border_radius=12,border=ft.border.all(1,_CARD_BD),
                                 bgcolor=_CARD_BG,padding=8,content=self.income_list),
                ],spacing=10,expand=True)))

    def _build_expenses_tab(self) -> ft.Tab:
        am=ft.TextField(label="Monto RD$",hint_text="500",keyboard_type=ft.KeyboardType.NUMBER,width=260)
        de=ft.TextField(label="Descripcion",hint_text="Supermercado",width=320)
        df=ft.TextField(label="Fecha",value=date.today().strftime("%Y-%m-%d"),width=200)
        df_row = self._date_field_row(df)
        ca=ft.Dropdown(label="Categoria",options=self._cat_opts(),width=260)
        src=ft.Dropdown(
            label="Descontar de",
            width=260,
            value="sueldo",
            options=[
                ft.dropdown.Option("sueldo", "Sueldo del período"),
                ft.dropdown.Option("ahorro", "Ahorro total"),
            ],
        )
        def on_save(_):
            a=(am.value or "").strip(); d=(de.value or "").strip()
            dt=(df.value or "").strip(); c=ca.value
            source = (src.value or "sueldo").strip().lower()
            if not all([a,d,dt,c]): self._snack("Completa todo.",error=True); return
            try:
                v=float(a)
                if v<=0: raise ValueError
            except ValueError: self._snack("Monto invalido.",error=True); return
            if not self._vdate(dt): self._snack("Fecha invalida.",error=True); return
            deducted_from_savings = False
            if source == "ahorro":
                if not self.service.withdraw_savings(v):
                    self._snack("Fondos insuficientes en ahorro.", error=True); return
                deducted_from_savings = True
            try:
                self.service.add_expense(v,d,int(c),dt,source=source)
            except Exception:
                if deducted_from_savings:
                    try:
                        self.service.add_savings(v)
                    except Exception:
                        logger.exception("rollback_savings_expense")
                self._snack("No se pudo guardar el gasto.",error=True); return
            am.value="";de.value="";df.value=date.today().strftime("%Y-%m-%d");ca.value=None; src.value="sueldo"
            self._refresh_all(); self._snack("Gasto guardado.")
        return ft.Tab(text="Nuevo gasto", icon=ft.Icons.ADD_CIRCLE_OUTLINE,
            content=ft.Container(expand=True, padding=ft.padding.only(top=24,left=8),
                content=ft.Column([
                    ft.Text("Registrar gasto",size=18,weight=ft.FontWeight.W_600),
                    ft.Container(height=4), am,de,df_row,ca,src, ft.Container(height=8),
                    ft.FilledButton("Guardar gasto",icon=ft.Icons.SAVE,on_click=on_save,
                                    style=ft.ButtonStyle(bgcolor=_PRIMARY)),
                ],spacing=10)))

    def _build_fixed_tab(self) -> ft.Tab:
        nf=ft.TextField(label="Nombre",hint_text="Netflix",width=260)
        af=ft.TextField(label="Monto RD$",hint_text="270",keyboard_type=ft.KeyboardType.NUMBER,width=200)
        dayf=ft.TextField(label="Fecha (dia del mes)",hint_text="1-31",keyboard_type=ft.KeyboardType.NUMBER,width=170)
        cf=ft.Dropdown(label="Categoria (opc.)",options=self._cat_opts(),width=260)
        def on_save(_):
            n=(nf.value or "").strip(); a=(af.value or "").strip(); d=(dayf.value or "").strip()
            if not all([n,a,d]): self._snack("Completa campos.",error=True); return
            try:
                v=float(a); day=int(d)
                if v<=0 or not(1<=day<=31): raise ValueError
            except ValueError: self._snack("Invalido.",error=True); return
            cid=int(cf.value) if cf.value else None
            try: self.service.add_fixed_payment(n,v,day,cid)
            except Exception: self._snack("No se pudo guardar el pago fijo.",error=True); return
            nf.value="";af.value="";dayf.value="";cf.value=None
            self._refresh_all(); self._snack("Pago fijo guardado.")
        return ft.Tab(text="Pagos fijos", icon=ft.Icons.REPEAT,
            content=ft.Container(expand=True, padding=ft.padding.only(top=16,left=8),
                content=ft.Column([
                    ft.Text("Pagos fijos",size=18,weight=ft.FontWeight.W_600),
                    ft.Container(expand=True, border_radius=12,border=ft.border.all(1,_CARD_BD),
                                 bgcolor=_CARD_BG,padding=8,content=self.fixed_list),
                    ft.Divider(),
                    ft.Text("Agregar pago fijo",size=16,weight=ft.FontWeight.W_600),
                    nf,af,dayf,cf,ft.Container(height=8),
                    ft.FilledButton("Guardar",icon=ft.Icons.SAVE,on_click=on_save,
                                    style=ft.ButtonStyle(bgcolor=_PRIMARY)),
                ],spacing=10,expand=True)))

    def _build_savings_tab(self) -> ft.Tab:
        dep_f = ft.TextField(label="Depositar en este período RD$",hint_text="7500",
                             keyboard_type=ft.KeyboardType.NUMBER,width=260)
        wit_f = ft.TextField(label="Retirar del ahorro total RD$",hint_text="2000",
                             keyboard_type=ft.KeyboardType.NUMBER,width=260)
        gn = ft.TextField(label="Nombre meta",hint_text="Viaje",width=260)
        ga = ft.TextField(label="Meta RD$",hint_text="100000",
                          keyboard_type=ft.KeyboardType.NUMBER,width=200)

        def on_dep(_):
            a=(dep_f.value or "").strip()
            if not a: self._snack("Ingresa monto.",error=True); return
            try:
                v=float(a)
                if v<=0: raise ValueError
            except ValueError: self._snack("Invalido.",error=True); return
            self.service.add_savings(v); dep_f.value=""
            self._refresh_all(); self._snack("Ahorro depositado.")

        def on_wit(_):
            a=(wit_f.value or "").strip()
            if not a: self._snack("Ingresa monto.",error=True); return
            try:
                v=float(a)
                if v<=0: raise ValueError
            except ValueError: self._snack("Invalido.",error=True); return
            if self.service.withdraw_savings(v):
                wit_f.value=""; self._refresh_all()
                self._snack("Retiro de ahorro exitoso.")
            else:
                self._snack("Fondos insuficientes.",error=True)

        def on_goal(_):
            n=(gn.value or "").strip(); a=(ga.value or "").strip()
            if not n or not a: self._snack("Completa campos.",error=True); return
            try:
                v=float(a)
                if v<=0: raise ValueError
            except ValueError: self._snack("Invalido.",error=True); return
            self.service.add_savings_goal(n,v)
            gn.value=""; ga.value=""
            self._refresh_all(); self._snack("Meta creada.")

        return ft.Tab(text="Ahorro", icon=ft.Icons.SAVINGS,
            content=ft.Container(expand=True, padding=ft.padding.only(top=16,left=8),
                content=ft.Column([
                    ft.Text("Ahorro",size=18,weight=ft.FontWeight.W_600),
                    ft.ResponsiveRow([
                        ft.Container(
                            col={"xs":12,"md":6},
                            padding=10,
                            border_radius=10,
                            border=ft.border.all(1,_CARD_BD),
                            bgcolor=_CARD_BG,
                            content=ft.Column([
                                ft.Text("Ahorro de este período", size=14, weight=ft.FontWeight.W_600),
                                self.lbl_period_savings_current,
                                ft.Row([
                                    dep_f,
                                    ft.FilledButton("Depositar",icon=ft.Icons.ADD,on_click=on_dep,
                                                    style=ft.ButtonStyle(bgcolor=_SUCCESS)),
                                ], spacing=10),
                            ], spacing=8),
                        ),
                        ft.Container(
                            col={"xs":12,"md":6},
                            padding=10,
                            border_radius=10,
                            border=ft.border.all(1,_CARD_BD),
                            bgcolor=_CARD_BG,
                            content=ft.Column([
                                ft.Text("Ahorro total", size=14, weight=ft.FontWeight.W_600),
                                self.lbl_total_savings_available,
                                ft.Row([
                                    wit_f,
                                    ft.FilledButton("Retirar",icon=ft.Icons.REMOVE,on_click=on_wit,
                                                    style=ft.ButtonStyle(bgcolor=_WARN)),
                                ], spacing=10),
                            ], spacing=8),
                        ),
                    ], spacing=12, run_spacing=12),
                    ft.Divider(),
                    ft.Text("Metas de ahorro",size=16,weight=ft.FontWeight.W_600),
                    ft.Container(expand=True, border_radius=12,border=ft.border.all(1,_CARD_BD),
                                 bgcolor=_CARD_BG,padding=8,content=self.goals_list),
                    ft.Divider(),
                    ft.Text("Agregar meta",size=16,weight=ft.FontWeight.W_600),
                    gn, ga, ft.Container(height=4),
                    ft.FilledButton("Crear meta",icon=ft.Icons.FLAG,on_click=on_goal,
                                    style=ft.ButtonStyle(bgcolor=_PRIMARY)),
                ],spacing=10,expand=True)))

    def _build_loans_tab(self) -> ft.Tab:
        pf=ft.TextField(label="Persona",hint_text="Nombre",width=260)
        af=ft.TextField(label="Monto RD$",hint_text="500",keyboard_type=ft.KeyboardType.NUMBER,width=200)
        df_=ft.TextField(label="Motivo (opc.)",hint_text="gasolina",width=320)
        dtf=ft.TextField(label="Fecha",value=date.today().strftime("%Y-%m-%d"),width=200)
        dtf_row = self._date_field_row(dtf)
        ded=ft.Dropdown(label="Descontar de...", width=260,
                        options=[ft.dropdown.Option("ninguno","No descontar"),
                                 ft.dropdown.Option("gasto","Descontar como gasto"),
                                 ft.dropdown.Option("ahorro","Descontar del ahorro")])
        ded.value = "ninguno"

        def on_save(_):
            p=(pf.value or "").strip(); a=(af.value or "").strip()
            dt=(dtf.value or "").strip()
            if not p or not a: self._snack("Completa persona y monto.",error=True); return
            try:
                v=float(a)
                if v<=0: raise ValueError
            except ValueError: self._snack("Invalido.",error=True); return
            if dt and not self._vdate(dt): self._snack("Fecha invalida.",error=True); return
            if not dt: dt=date.today().strftime("%Y-%m-%d")
            desc=(df_.value or "").strip()
            deduction = ded.value or "ninguno"

            # Si descuenta del ahorro, retirar
            if deduction == "ahorro":
                if not self.service.withdraw_savings(v):
                    self._snack("Ahorro insuficiente para descontar.",error=True); return

            # Si descuenta como gasto, crear gasto automatico
            if deduction == "gasto":
                cats = self.service.get_categories()
                otros_cat = next((c for c in cats if c["name"].lower() in ["otros","prestamos"]), cats[-1] if cats else None)
                if otros_cat:
                    self.service.add_expense(v, f"Prestamo a {p}", otros_cat["id"], dt)

            try: self.service.add_loan(p,v,desc,dt,deduction)
            except Exception: self._snack("No se pudo registrar el préstamo.",error=True); return
            pf.value="";af.value="";df_.value="";dtf.value=date.today().strftime("%Y-%m-%d")
            ded.value="ninguno"
            self._refresh_all(); self._snack("Prestamo registrado.")

        return ft.Tab(text="Prestamos", icon=ft.Icons.MONEY_OFF,
            content=ft.Container(expand=True, padding=ft.padding.only(top=16,left=8),
                content=ft.Column([
                    ft.Text("Dinero prestado",size=18,weight=ft.FontWeight.W_600),
                    ft.Container(expand=True, border_radius=12,border=ft.border.all(1,_CARD_BD),
                                 bgcolor=_CARD_BG,padding=8,content=self.loans_list),
                    ft.Divider(),
                    ft.Text("Nuevo prestamo",size=16,weight=ft.FontWeight.W_600),
                    pf,af,df_,dtf_row,ded,ft.Container(height=8),
                    ft.FilledButton("Guardar",icon=ft.Icons.SAVE,on_click=on_save,
                                    style=ft.ButtonStyle(bgcolor=_PRIMARY)),
                ],spacing=10,expand=True)))

    def _build_settings_tab(self) -> ft.Tab:
        period_mode = self.service.get_period_mode()
        auto_export = self._get_bool_setting("auto_export_close_period", False)
        include_beta_updates = self._get_bool_setting("include_beta_updates", False)
        q_day_1 = self.service._get_int_setting("quincenal_pay_day_1", 1)
        q_day_2 = self.service._get_int_setting("quincenal_pay_day_2", 16)
        m_day = self.service._get_int_setting("monthly_pay_day", 1)

        mode_dd = ft.Dropdown(
            label="Frecuencia de reporte y salario",
            width=280,
            value=period_mode,
            options=[
                ft.dropdown.Option("quincenal", "Quincenal"),
                ft.dropdown.Option("mensual", "Mensual"),
            ],
        )

        auto_sw = ft.Switch(
            label="Exportación automática al cerrar período",
            value=auto_export,
        )

        beta_sw = ft.Switch(
            label="Incluir versiones beta en actualizaciones",
            value=include_beta_updates,
        )

        q_day_1_tf = ft.TextField(
            label="Día cobro quincena 1",
            hint_text="1-31",
            keyboard_type=ft.KeyboardType.NUMBER,
            value=str(q_day_1),
            width=170,
        )
        q_day_2_tf = ft.TextField(
            label="Día cobro quincena 2",
            hint_text="1-31",
            keyboard_type=ft.KeyboardType.NUMBER,
            value=str(q_day_2),
            width=170,
        )
        m_day_tf = ft.TextField(
            label="Día cobro mensual",
            hint_text="1-31",
            keyboard_type=ft.KeyboardType.NUMBER,
            value=str(m_day),
            width=170,
        )

        def _parse_day(text: str, label: str) -> Optional[int]:
            raw = (text or "").strip()
            if not raw:
                self._snack(f"Completa {label}.", error=True)
                return None
            if not raw.isdigit():
                self._snack(f"{label} debe ser un número entre 1 y 31.", error=True)
                return None
            day = int(raw)
            if day < 1 or day > 31:
                self._snack(f"{label} debe estar entre 1 y 31.", error=True)
                return None
            return day

        def on_save_general(_):
            mode = (mode_dd.value or "quincenal").strip().lower()
            q1 = _parse_day(q_day_1_tf.value, "día de cobro quincena 1")
            if q1 is None:
                return
            q2 = _parse_day(q_day_2_tf.value, "día de cobro quincena 2")
            if q2 is None:
                return
            md = _parse_day(m_day_tf.value, "día de cobro mensual")
            if md is None:
                return
            if q1 == q2:
                self._snack("Los dos días de cobro quincenal no pueden ser iguales.", error=True)
                return
            if q1 > q2:
                self._snack("En quincenal, el día 1 debe ser menor que el día 2.", error=True)
                return

            self.service.set_setting("quincenal_pay_day_1", str(q1))
            self.service.set_setting("quincenal_pay_day_2", str(q2))
            self.service.set_setting("monthly_pay_day", str(md))
            self.service.set_period_mode(mode)
            self._set_bool_setting("auto_export_close_period", bool(auto_sw.value))
            self._set_bool_setting("include_beta_updates", bool(beta_sw.value))
            if mode == "mensual":
                self._vc = 1
            else:
                t = date.today()
                if self._vy == t.year and self._vm == t.month:
                    self._vc = self.service.get_cycle_for_date(t)
            self._reload_ui()
            self._snack("Configuración general guardada.")

        def on_check_updates(_):
            self._check_for_updates(manual=True, include_beta=bool(beta_sw.value))

        new_cat = ft.TextField(label="Nueva categoría", hint_text="Ej: Educación", width=260)

        def on_add_category(_):
            name = (new_cat.value or "").strip()
            if not name:
                self._snack("Completa campos.", error=True); return
            try:
                self.service.add_category(name)
            except Exception:
                self._snack("No se pudo crear la categoría (quizás ya existe).", error=True); return
            new_cat.value = ""
            self._reload_ui()
            self._snack("Categoría creada correctamente.")

        cat_rows: List[ft.Control] = []
        for cat in self.service.get_categories():
            cid = int(cat["id"])
            cname = str(cat.get("name") or "(sin nombre)")

            def _on_rename(_, _cid=cid, _name=cname):
                name_f = ft.TextField(label="Nuevo nombre", value=_name, width=280)

                def _save_name(__):
                    new_name = (name_f.value or "").strip()
                    if not new_name:
                        self._snack("Completa campos.", error=True); return
                    try:
                        self.service.rename_category(_cid, new_name)
                    except Exception:
                        self._snack("No se pudo renombrar la categoría.", error=True); return
                    dlg.open = False
                    self._reload_ui()
                    self._snack("Categoría actualizada correctamente.")

                def _close_name(__):
                    dlg.open = False
                    self.page.update()

                dlg = ft.AlertDialog(
                    title=ft.Text("Renombrar categoría", weight=ft.FontWeight.BOLD, color=_PRIMARY),
                    content=ft.Column([name_f], tight=True, width=320),
                    actions=[
                        ft.TextButton("Cancelar", on_click=_close_name),
                        ft.FilledButton("Guardar", icon=ft.Icons.SAVE, on_click=_save_name,
                                        style=ft.ButtonStyle(bgcolor=_PRIMARY)),
                    ],
                    actions_alignment=ft.MainAxisAlignment.END,
                )
                self.page.overlay.append(dlg)
                dlg.open = True
                self.page.update()

            def _on_delete(_, _cid=cid, _name=cname):
                try:
                    self.service.delete_category(_cid)
                except ValueError as e:
                    self._snack(str(e), error=True); return
                except Exception:
                    self._snack("No se pudo eliminar la categoría.", error=True); return
                self._reload_ui()
                self._snack(f"Categoría eliminada: {_name}")

            cat_rows.append(
                ft.Container(
                    padding=ft.padding.symmetric(horizontal=10, vertical=6),
                    border_radius=8,
                    bgcolor="#F5F5F5",
                    content=ft.Row([
                        ft.Text(cname, expand=True),
                        ft.IconButton(
                            ft.Icons.EDIT_OUTLINED,
                            tooltip="Renombrar categoría",
                            icon_color=_PRIMARY,
                            on_click=_on_rename,
                        ),
                        ft.IconButton(
                            ft.Icons.DELETE_OUTLINE,
                            tooltip="Eliminar categoría",
                            icon_color=_ERROR,
                            on_click=_on_delete,
                        ),
                    ])
                )
            )

        if not cat_rows:
            cat_rows.append(ft.Text("Sin categorías", color=_SUBTITLE, italic=True))

        categories_view = ft.ListView(controls=cat_rows, spacing=6, expand=True)

        return ft.Tab(
            text="Configuración",
            icon=ft.Icons.SETTINGS,
            content=ft.Container(
                expand=True,
                padding=ft.padding.only(top=16, left=8),
                content=ft.Column([
                    ft.Text("Configuración", size=18, weight=ft.FontWeight.W_600),
                    ft.Text("Personaliza frecuencia, días de cobro, exportación y categorías.", size=12, color=_SUBTITLE),
                    ft.Divider(),
                    ft.Text("General", size=16, weight=ft.FontWeight.W_600),
                    ft.Row([mode_dd, auto_sw, beta_sw], spacing=16, wrap=True),
                    ft.Row([q_day_1_tf, q_day_2_tf, m_day_tf], spacing=16, wrap=True),
                    ft.Text(
                        "Los días de cobro se aplican automáticamente en cada período.\n"
                        "Quincenal: Q1 inicia en día 1 y Q2 en día 2.\n"
                        "Mensual: el mes inicia en ese día y termina el día anterior del próximo mes.",
                        size=12,
                        color=_SUBTITLE,
                    ),
                    ft.FilledButton(
                        "Guardar configuración",
                        icon=ft.Icons.SAVE,
                        on_click=on_save_general,
                        style=ft.ButtonStyle(bgcolor=_PRIMARY),
                    ),
                    ft.OutlinedButton(
                        "Buscar actualización",
                        icon=ft.Icons.SYSTEM_UPDATE,
                        on_click=on_check_updates,
                        style=ft.ButtonStyle(color=_WARN),
                    ),
                    ft.Divider(),
                    ft.Text("Respaldo y restauración", size=16, weight=ft.FontWeight.W_600),
                    ft.Row([
                        ft.FilledButton("Crear respaldo", icon=ft.Icons.BACKUP,
                                        on_click=lambda _: self._create_backup(),
                                        style=ft.ButtonStyle(bgcolor=_PRIMARY)),
                        ft.OutlinedButton("Restaurar último respaldo", icon=ft.Icons.RESTORE,
                                          on_click=lambda _: self._restore_latest_backup()),
                    ], spacing=10, wrap=True),
                    ft.Text("La restauración aplica el último respaldo disponible.", size=12, color=_SUBTITLE),
                    ft.Divider(),
                    ft.Text("Categorías", size=16, weight=ft.FontWeight.W_600),
                    ft.Row([
                        new_cat,
                        ft.FilledButton("Agregar categoría", icon=ft.Icons.ADD,
                                        on_click=on_add_category,
                                        style=ft.ButtonStyle(bgcolor=_SUCCESS)),
                    ], spacing=10, wrap=True),
                    ft.Container(
                        expand=True,
                        border_radius=12,
                        border=ft.border.all(1, _CARD_BD),
                        bgcolor=_CARD_BG,
                        padding=8,
                        content=categories_view,
                    ),
                ], spacing=10, expand=True, scroll=ft.ScrollMode.AUTO)
            )
        )

    # ═══════════════════════ DATA LOAD ═══════════════════════
    def _load_data(self):
        try: data = self.service.get_dashboard_data(self._vy, self._vm, self._vc)
        except Exception:
            logger.exception("load"); return

        self.lbl_dinero_ini.value  = format_currency(data["dinero_inicial"])
        self.lbl_total_gasto.value = format_currency(data["total_expenses"])
        self.lbl_ahorro_tot.value  = format_currency(data["total_savings"])
        self.lbl_period_savings_current.value = f"Actual: {format_currency(data.get('period_savings', 0.0))}"
        self.lbl_total_savings_available.value = f"Disponible: {format_currency(data['total_savings'])}"
        self.lbl_avg_daily.value   = format_currency(data["avg_daily"])
        self.lbl_loans.value       = format_currency(data["total_loans"])

        disp = data["dinero_disponible"]
        self.lbl_dinero_disp.value = format_currency(disp)
        self.lbl_dinero_disp.color = _SUCCESS if disp >= 0 else _ERROR

        self.quincenal_label.value = self._qlabel_smart(data)

        # chart
        self.chart_container.content = self._build_pie(
            data["cat_totals"], data["categories_by_id"])

        # recent expenses + vencimientos de pagos fijos
        self.recent_list.controls.clear()
        recent_items = data.get("recent_expenses", [])
        if not recent_items:
            self.recent_list.controls.append(
                ft.Text("Sin gastos",italic=True,color=_SUBTITLE))
        for item in recent_items:
            row_type = item.get("type", "expense")
            is_fixed_due = row_type == "fixed_due"
            row_bg = "#FFF8E1" if is_fixed_due else "#F5F5F5"
            amount_color = _WARN if is_fixed_due else _ERROR
            cat_str = str(item.get("categories") or "Sin cat.")
            self.recent_list.controls.append(ft.Container(
                padding=ft.padding.symmetric(horizontal=12,vertical=8),
                border_radius=8, bgcolor=row_bg,
                content=ft.Row([
                    ft.Column([
                        ft.Text(str(item.get("description", "")),weight=ft.FontWeight.W_500),
                        ft.Text(f'{item.get("date", "")}  ·  {cat_str}',size=12,color=_SUBTITLE),
                    ],spacing=2,expand=True),
                    ft.Text(format_currency(float(item.get("amount") or 0)),
                            weight=ft.FontWeight.BOLD,color=amount_color),
                    *(
                        [
                            ft.IconButton(ft.Icons.EDIT_OUTLINED, icon_color=_PRIMARY, icon_size=18,
                                          tooltip="Editar",
                                          on_click=lambda _, _e=dict(item.get("raw") or {}): self._open_edit_expense(_e)),
                            ft.IconButton(ft.Icons.DELETE_OUTLINE, icon_color=_ERROR, icon_size=18,
                                          tooltip="Eliminar",
                                          on_click=lambda _, _id=int(item.get("id")): self._del_expense(_id)),
                        ] if not is_fixed_due and item.get("id") else [
                            ft.Icon(ft.Icons.EVENT, color=_WARN, size=18)
                        ]
                    ),
                ])))

        # fixed
        self.fixed_list.controls.clear()
        fps = data.get("fixed_payments",[])
        if not fps:
            self.fixed_list.controls.append(ft.Text("Sin pagos fijos",italic=True,color=_SUBTITLE))
        for fp in fps:
            pid=fp["id"]
            due_label = fp.get("due_date") or str(fp.get("due_day", "-"))
            self.fixed_list.controls.append(ft.Container(
                padding=ft.padding.symmetric(horizontal=12,vertical=8),
                border_radius=8,bgcolor="#F5F5F5",
                content=ft.Row([
                    ft.Column([ft.Text(fp["name"],weight=ft.FontWeight.W_500),
                               ft.Text(f'Fecha {due_label}',size=12,color=_SUBTITLE)],
                              spacing=2,expand=True),
                    ft.Text(format_currency(float(fp["amount"])),weight=ft.FontWeight.BOLD),
                    ft.IconButton(ft.Icons.EDIT_OUTLINED,icon_color=_PRIMARY,icon_size=18,
                                  tooltip="Editar",
                                  on_click=lambda _,_fp=dict(fp):self._open_edit_fixed(_fp)),
                    ft.IconButton(ft.Icons.DELETE_OUTLINE,icon_color=_ERROR,icon_size=18,
                                  tooltip="Eliminar",
                                  on_click=lambda _,fpid=pid:self._del_fixed(fpid)),
                ])))

        # loans
        self.loans_list.controls.clear()
        loans = self.service.get_loans(include_paid=True)
        if not loans:
            self.loans_list.controls.append(ft.Text("Sin prestamos",italic=True,color=_SUBTITLE))
        for loan in loans:
            lid=loan["id"]; paid=bool(loan.get("is_paid"))
            st="PAGADO" if paid else "PENDIENTE"
            sc=_SUCCESS if paid else _WARN
            ded_type = loan.get("deduction_type","") or ""
            ded_label = ""
            if ded_type == "gasto": ded_label = " · Desc. gasto"
            elif ded_type == "ahorro": ded_label = " · Desc. ahorro"
            acts=[]
            if not paid:
                acts.append(ft.IconButton(ft.Icons.CHECK_CIRCLE_OUTLINE,icon_color=_SUCCESS,
                    icon_size=20,tooltip="Pagado",
                    on_click=lambda _,_l=lid:self._mark_paid(_l)))
            acts.append(ft.IconButton(ft.Icons.EDIT_OUTLINED,icon_color=_PRIMARY,
                icon_size=18,tooltip="Editar",
                on_click=lambda _,_ln=dict(loan):self._open_edit_loan(_ln)))
            acts.append(ft.IconButton(ft.Icons.DELETE_OUTLINE,icon_color=_ERROR,
                icon_size=18,tooltip="Eliminar",
                on_click=lambda _,_l=lid:self._del_loan(_l)))
            desc=str(loan.get("description","")) if loan.get("description") else ""
            sub=[str(loan["date"])]
            if desc: sub.append(desc)
            self.loans_list.controls.append(ft.Container(
                padding=ft.padding.symmetric(horizontal=12,vertical=8),
                border_radius=8,bgcolor="#F5F5F5",
                content=ft.Row([
                    ft.Column([
                        ft.Text(str(loan["person"]),weight=ft.FontWeight.W_500),
                        ft.Text("  ·  ".join(sub)+ded_label,size=12,color=_SUBTITLE),
                    ],spacing=2,expand=True),
                    ft.Container(padding=ft.padding.symmetric(horizontal=8,vertical=2),
                                 border_radius=6,bgcolor=sc,
                                 content=ft.Text(st,size=11,color="white",
                                                 weight=ft.FontWeight.BOLD)),
                    ft.Text(format_currency(float(loan["amount"])),weight=ft.FontWeight.BOLD),
                    *acts,
                ])))

        # incomes
        self.income_list.controls.clear()
        try:
            incomes=self.service.get_incomes(data["year"],data["month"],data["cycle"])
            if not incomes:
                self.income_list.controls.append(
                    ft.Text("Sin ingresos extras",italic=True,color=_SUBTITLE))
            for inc in incomes:
                iid=inc["id"]
                self.income_list.controls.append(ft.Container(
                    padding=ft.padding.symmetric(horizontal=12,vertical=8),
                    border_radius=8,bgcolor="#F5F5F5",
                    content=ft.Row([
                        ft.Column([ft.Text(inc["description"],weight=ft.FontWeight.W_500),
                                   ft.Text(str(inc["date"]),size=12,color=_SUBTITLE)],
                                  spacing=2,expand=True),
                        ft.Text(format_currency(float(inc["amount"])),
                                weight=ft.FontWeight.BOLD,color=_SUCCESS),
                        ft.IconButton(ft.Icons.EDIT_OUTLINED,icon_color=_PRIMARY,icon_size=18,
                                      tooltip="Editar",
                                      on_click=lambda _,_inc=dict(inc):self._open_edit_income(_inc)),
                        ft.IconButton(ft.Icons.DELETE_OUTLINE,icon_color=_ERROR,icon_size=18,
                                      tooltip="Eliminar",
                                      on_click=lambda _,_i=iid:self._del_income(_i)),
                    ])))
        except Exception:
            logger.exception("incomes")

        # savings goals
        self.goals_list.controls.clear()
        total_savings = data["total_savings"]
        goals = self.service.get_savings_goals()
        if not goals:
            self.goals_list.controls.append(
                ft.Text("Sin metas de ahorro",italic=True,color=_SUBTITLE))
        for g in goals:
            gid=g["id"]; target=float(g["target_amount"])
            pct=min(total_savings/target,1.0) if target>0 else 0
            self.goals_list.controls.append(ft.Container(
                padding=ft.padding.symmetric(horizontal=12,vertical=8),
                border_radius=8,bgcolor="#F5F5F5",
                content=ft.Column([
                    ft.Row([
                        ft.Text(g["name"],weight=ft.FontWeight.W_500,expand=True),
                        ft.Text(f"{format_currency(total_savings)} / {format_currency(target)}",
                                size=12,color=_SUBTITLE),
                        ft.IconButton(ft.Icons.EDIT_OUTLINED,icon_color=_PRIMARY,icon_size=18,
                                      tooltip="Editar",
                                      on_click=lambda _,_g=dict(g):self._open_edit_goal(_g)),
                        ft.IconButton(ft.Icons.DELETE_OUTLINE,icon_color=_ERROR,icon_size=18,
                                      tooltip="Eliminar",
                                      on_click=lambda _,_g=gid:self._del_goal(_g)),
                    ]),
                    ft.ProgressBar(value=pct, color=_SUCCESS if pct<1 else _PRIMARY,
                                   bgcolor=_CARD_BD),
                    ft.Text(f"{pct*100:.0f}% completado",size=11,
                            color=_SUCCESS if pct>=1 else _SUBTITLE),
                ],spacing=4)))

    def _refresh_all(self):
        self._load_data()
        if self.page: self.page.update()

    # ═══════════════════════ EDIT DIALOGS ═══════════════════════

    def _open_edit_expense(self, expense):
        """Abrir diálogo para editar un gasto."""
        am = ft.TextField(label="Monto RD$", value=str(float(expense["amount"])),
                          keyboard_type=ft.KeyboardType.NUMBER, width=260)
        de = ft.TextField(label="Descripcion", value=str(expense["description"]), width=320)
        df = ft.TextField(label="Fecha", value=str(expense["date"])[:10], width=200)
        df_row = self._date_field_row(df)
        ca = ft.Dropdown(label="Categoria", options=self._cat_opts(), width=260)
        # pre-select category
        if expense.get("category_ids"):
            first_cid = str(expense["category_ids"]).split(",")[0].strip()
            if first_cid.isdigit():
                ca.value = first_cid
        eid = expense["id"]

        def on_save(_):
            a = (am.value or "").strip(); d = (de.value or "").strip()
            dt = (df.value or "").strip(); c = ca.value
            if not all([a, d, dt, c]):
                self._snack("Completa todo.", error=True); return
            try:
                v = float(a)
                if v <= 0: raise ValueError
            except ValueError:
                self._snack("Monto inválido.", error=True); return
            if not self._vdate(dt):
                self._snack("Fecha inválida.", error=True); return
            self.service.update_expense(eid, v, d, dt, int(c))
            dlg.open = False
            self._refresh_all()
            self._snack("Gasto actualizado.")

        def on_close(_):
            dlg.open = False
            self.page.update()

        dlg = ft.AlertDialog(
            title=ft.Text("Editar gasto", weight=ft.FontWeight.BOLD, color=_PRIMARY),
            content=ft.Column([am, de, df_row, ca], spacing=10, tight=True, width=340),
            actions=[ft.TextButton("Cancelar", on_click=on_close),
                     ft.FilledButton("Guardar", icon=ft.Icons.SAVE, on_click=on_save,
                                     style=ft.ButtonStyle(bgcolor=_PRIMARY))],
            actions_alignment=ft.MainAxisAlignment.END)
        self.page.overlay.append(dlg)
        dlg.open = True
        self.page.update()

    def _open_edit_fixed(self, fp):
        """Abrir diálogo para editar un pago fijo."""
        nf = ft.TextField(label="Nombre", value=str(fp["name"]), width=260)
        af = ft.TextField(label="Monto RD$", value=str(float(fp["amount"])),
                          keyboard_type=ft.KeyboardType.NUMBER, width=200)
        dayf = ft.TextField(label="Dia", value=str(fp["due_day"]),
                            keyboard_type=ft.KeyboardType.NUMBER, width=120)
        cf = ft.Dropdown(label="Categoria", options=self._cat_opts(), width=260)
        if fp.get("category_id"):
            cf.value = str(fp["category_id"])
        pid = fp["id"]

        def on_save(_):
            n = (nf.value or "").strip(); a = (af.value or "").strip()
            d = (dayf.value or "").strip()
            if not all([n, a, d]):
                self._snack("Completa campos.", error=True); return
            try:
                v = float(a); day = int(d)
                if v <= 0 or not (1 <= day <= 31): raise ValueError
            except ValueError:
                self._snack("Inválido.", error=True); return
            cid = int(cf.value) if cf.value else None
            self.service.update_fixed_payment(pid, n, v, day, cid)
            dlg.open = False
            self._refresh_all()
            self._snack("Pago fijo actualizado.")

        def on_close(_):
            dlg.open = False
            self.page.update()

        dlg = ft.AlertDialog(
            title=ft.Text("Editar pago fijo", weight=ft.FontWeight.BOLD, color=_PRIMARY),
            content=ft.Column([nf, af, dayf, cf], spacing=10, tight=True, width=340),
            actions=[ft.TextButton("Cancelar", on_click=on_close),
                     ft.FilledButton("Guardar", icon=ft.Icons.SAVE, on_click=on_save,
                                     style=ft.ButtonStyle(bgcolor=_PRIMARY))],
            actions_alignment=ft.MainAxisAlignment.END)
        self.page.overlay.append(dlg)
        dlg.open = True
        self.page.update()

    def _open_edit_loan(self, loan):
        """Abrir diálogo para editar un préstamo."""
        pf = ft.TextField(label="Persona", value=str(loan["person"]), width=260)
        af = ft.TextField(label="Monto RD$", value=str(float(loan["amount"])),
                          keyboard_type=ft.KeyboardType.NUMBER, width=200)
        df_ = ft.TextField(label="Motivo", value=str(loan.get("description", "") or ""), width=320)
        ded = ft.Dropdown(label="Descontar de...", width=260,
                          options=[ft.dropdown.Option("ninguno", "No descontar"),
                                   ft.dropdown.Option("gasto", "Descontar como gasto"),
                                   ft.dropdown.Option("ahorro", "Descontar del ahorro")])
        ded.value = loan.get("deduction_type", "ninguno") or "ninguno"
        lid = loan["id"]

        def on_save(_):
            p = (pf.value or "").strip(); a = (af.value or "").strip()
            if not p or not a:
                self._snack("Completa persona y monto.", error=True); return
            try:
                v = float(a)
                if v <= 0: raise ValueError
            except ValueError:
                self._snack("Inválido.", error=True); return
            desc = (df_.value or "").strip()
            deduction = ded.value or "ninguno"
            self.service.update_loan(lid, p, v, desc, deduction)
            dlg.open = False
            self._refresh_all()
            self._snack("Préstamo actualizado.")

        def on_close(_):
            dlg.open = False
            self.page.update()

        dlg = ft.AlertDialog(
            title=ft.Text("Editar préstamo", weight=ft.FontWeight.BOLD, color=_PRIMARY),
            content=ft.Column([pf, af, df_, ded], spacing=10, tight=True, width=340),
            actions=[ft.TextButton("Cancelar", on_click=on_close),
                     ft.FilledButton("Guardar", icon=ft.Icons.SAVE, on_click=on_save,
                                     style=ft.ButtonStyle(bgcolor=_PRIMARY))],
            actions_alignment=ft.MainAxisAlignment.END)
        self.page.overlay.append(dlg)
        dlg.open = True
        self.page.update()

    def _open_edit_income(self, inc):
        """Abrir diálogo para editar un ingreso extra."""
        ia = ft.TextField(label="Monto RD$", value=str(float(inc["amount"])),
                          keyboard_type=ft.KeyboardType.NUMBER, width=200)
        id_ = ft.TextField(label="Descripcion", value=str(inc["description"]), width=300)
        idt = ft.TextField(label="Fecha", value=str(inc["date"])[:10], width=180)
        idt_row = self._date_field_row(idt)
        iid = inc["id"]

        def on_save(_):
            a = (ia.value or "").strip(); d = (id_.value or "").strip()
            dt = (idt.value or "").strip()
            if not a or not d:
                self._snack("Completa campos.", error=True); return
            try:
                v = float(a)
                if v <= 0: raise ValueError
            except ValueError:
                self._snack("Monto inválido.", error=True); return
            if dt and not self._vdate(dt):
                self._snack("Fecha inválida.", error=True); return
            if not dt: dt = date.today().strftime("%Y-%m-%d")
            self.service.update_income(iid, v, d, dt)
            dlg.open = False
            self._refresh_all()
            self._snack("Ingreso actualizado.")

        def on_close(_):
            dlg.open = False
            self.page.update()

        dlg = ft.AlertDialog(
            title=ft.Text("Editar ingreso", weight=ft.FontWeight.BOLD, color=_PRIMARY),
            content=ft.Column([ia, id_, idt_row], spacing=10, tight=True, width=340),
            actions=[ft.TextButton("Cancelar", on_click=on_close),
                     ft.FilledButton("Guardar", icon=ft.Icons.SAVE, on_click=on_save,
                                     style=ft.ButtonStyle(bgcolor=_PRIMARY))],
            actions_alignment=ft.MainAxisAlignment.END)
        self.page.overlay.append(dlg)
        dlg.open = True
        self.page.update()

    def _open_edit_goal(self, goal):
        """Abrir diálogo para editar una meta de ahorro."""
        gn = ft.TextField(label="Nombre meta", value=str(goal["name"]), width=260)
        ga = ft.TextField(label="Meta RD$", value=str(float(goal["target_amount"])),
                          keyboard_type=ft.KeyboardType.NUMBER, width=200)
        gid = goal["id"]

        def on_save(_):
            n = (gn.value or "").strip(); a = (ga.value or "").strip()
            if not n or not a:
                self._snack("Completa campos.", error=True); return
            try:
                v = float(a)
                if v <= 0: raise ValueError
            except ValueError:
                self._snack("Inválido.", error=True); return
            self.service.update_savings_goal(gid, n, v)
            dlg.open = False
            self._refresh_all()
            self._snack("Meta actualizada.")

        def on_close(_):
            dlg.open = False
            self.page.update()

        dlg = ft.AlertDialog(
            title=ft.Text("Editar meta", weight=ft.FontWeight.BOLD, color=_PRIMARY),
            content=ft.Column([gn, ga], spacing=10, tight=True, width=340),
            actions=[ft.TextButton("Cancelar", on_click=on_close),
                     ft.FilledButton("Guardar", icon=ft.Icons.SAVE, on_click=on_save,
                                     style=ft.ButtonStyle(bgcolor=_PRIMARY))],
            actions_alignment=ft.MainAxisAlignment.END)
        self.page.overlay.append(dlg)
        dlg.open = True
        self.page.update()

    # acciones
    def _del_expense(self, eid):
        self.db.delete_expense(eid); self._refresh_all()
        self._snack("Gasto eliminado.")
    def _del_fixed(self, pid):
        self.service.delete_fixed_payment(pid); self._refresh_all()
        self._snack("Pago fijo eliminado.")
    def _mark_paid(self, lid):
        self.service.mark_loan_paid(lid); self._refresh_all()
        self._snack("Prestamo pagado.")
    def _del_loan(self, lid):
        self.service.delete_loan(lid); self._refresh_all()
        self._snack("Prestamo eliminado.")
    def _del_income(self, iid):
        self.service.delete_income(iid); self._refresh_all()
        self._snack("Ingreso eliminado.")
    def _del_goal(self, gid):
        self.service.delete_savings_goal(gid); self._refresh_all()
        self._snack("Meta eliminada.")

    # ═══════════════════════ ALERTA QUINCENA ═══════════════════════
    def _check_quincenal_alert(self):
        mode = self.service.get_period_mode()
        today = date.today()

        if mode == "mensual":
            period_starts = self.service.get_period_start_days(today.year, today.month)
            if today.day not in period_starts:
                return
            if today.month == 1:
                py, pm = today.year - 1, 12
            else:
                py, pm = today.year, today.month - 1
            pc = 1
            period_label = f"Mensual {pm:02d}/{py}"
            export_key = f"M:{py}-{pm:02d}"
        else:
            period_starts = self.service.get_period_start_days(today.year, today.month)
            if today.day not in period_starts:
                return
            py, pm, pc = _prev_q(today.year, today.month, self.service.get_cycle_for_date(today))
            period_label = _qlabel(py, pm, pc)
            export_key = f"Q:{py}-{pm:02d}-{pc}"

        auto_export = self._get_bool_setting("auto_export_close_period", False)
        last_key = self.service.get_setting("last_auto_export_key", "")

        if auto_export and last_key != export_key:
            try:
                pdf_path = self.service.generate_report(py, pm, pc)
                csv_path = self.service.export_csv(py, pm, pc)
                self.service.set_setting("last_auto_export_key", export_key)
                self._snack(f"Exportación automática completada: {pdf_path.name} y {csv_path.name}")
            except Exception:
                logger.exception("auto_export")
                self._snack("Falló la exportación automática del período cerrado.", error=True)
            return

        def on_gen(_):
            try:
                p=self.service.generate_report(py,pm,pc)
                self._snack(f"PDF: {p.name}")
                try: os.startfile(str(p))
                except: pass
            except Exception: self._snack("Error.",error=True)
            if self.page and self.page.dialog:
                self.page.dialog.open=False; self.page.update()
        def on_close(_):
            if self.page and self.page.dialog:
                self.page.dialog.open=False; self.page.update()
        dlg=ft.AlertDialog(modal=True,
            title=ft.Text("Cierre de período",weight=ft.FontWeight.BOLD),
            content=ft.Column([
                ft.Text(f"Período anterior ({period_label}) terminó."),
                ft.Text("¿Deseas generar el reporte PDF?"),
            ],tight=True,spacing=8),
            actions=[ft.TextButton("No",on_click=on_close),
                     ft.FilledButton("Generar PDF",icon=ft.Icons.PICTURE_AS_PDF,
                                     on_click=on_gen,
                                     style=ft.ButtonStyle(bgcolor=_PRIMARY))],
            actions_alignment=ft.MainAxisAlignment.END)
        self.page.dialog=dlg; dlg.open=True; self.page.update()

    # ═══════════════════════ MAIN ═══════════════════════
    def main(self, page: ft.Page):
        self.page = page
        page.title = "RBP - Rivas Budget Planning"
        page.theme_mode = ft.ThemeMode.LIGHT
        page.padding = 0
        page.bgcolor = "#FAFAFA"

        # ── ICONO DE VENTANA ──
        # Flet usa un .ico vía la propiedad page (Flet 0.27+)
        # Intentar la ruta absoluta al .ico
        ico_path = BASE_DIR / "icon.ico"
        if not ico_path.exists():
            for _d in _asset_search_dirs():
                _candidate = _d / "icon.ico"
                if _candidate.exists():
                    ico_path = _candidate
                    break
        if ico_path.exists():
            try:
                page.window.icon = str(ico_path)
            except Exception:
                pass

        # Win32 API: forzar icono en la barra de tareas
        try:
            if os.name == "nt":
                ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(
                    "rbp.rivasbudgetplanning.1.0")
        except Exception:
            pass

        self._load_data()

        # título
        title_children = []
        if _ICON_B64:
            title_children.append(ft.Image(src_base64=_ICON_B64,width=36,height=36,
                                           fit=ft.ImageFit.CONTAIN))
        title_children += [
            ft.Text("Rivas Budget Planning",size=14,color=_SUBTITLE),
        ]

        tabs = ft.Tabs(selected_index=0, animation_duration=200, expand=True,
                        label_color=_PRIMARY, unselected_label_color=_SUBTITLE,
                        indicator_color=_PRIMARY,
                        tabs=[self._build_dashboard_tab(),
                              self._build_income_tab(),
                              self._build_expenses_tab(),
                              self._build_fixed_tab(),
                              self._build_loans_tab(),
                        self._build_savings_tab(),
                        self._build_settings_tab()])

        page.add(ft.Container(expand=True,
            padding=ft.padding.symmetric(horizontal=24,vertical=10),
            content=ft.Column([ft.Row(title_children,spacing=10),tabs],
                              expand=True,spacing=4)))

        # ── Win32: forzar icono real en la ventana y taskbar ──
        try:
            if os.name == "nt" and ico_path.exists():
                import time, threading
                def _set_win_icon():
                    time.sleep(2.0)  # esperar a que Flet/Flutter cree la ventana
                    try:
                        u32 = ctypes.windll.user32
                        k32 = ctypes.windll.kernel32
                        WM_SETICON = 0x0080
                        ICON_SMALL = 0
                        ICON_BIG = 1
                        IMAGE_ICON = 1
                        LR_LOADFROMFILE = 0x0010
                        GW_OWNER = 4

                        # Buscar la ventana de NUESTRO proceso (no la del foreground)
                        pid_actual = k32.GetCurrentProcessId()
                        hwnd_found = None

                        # Callback para EnumWindows
                        WNDENUMPROC = ctypes.WINFUNCTYPE(
                            ctypes.c_bool, ctypes.c_void_p, ctypes.c_void_p)

                        def enum_cb(hwnd, _):
                            nonlocal hwnd_found
                            # Solo ventanas visibles y de nivel superior (sin owner)
                            if not u32.IsWindowVisible(hwnd):
                                return True
                            if u32.GetWindow(hwnd, GW_OWNER):
                                return True
                            # Verificar que pertenece a nuestro proceso
                            win_pid = ctypes.c_ulong()
                            u32.GetWindowThreadProcessId(
                                hwnd, ctypes.byref(win_pid))
                            if win_pid.value == pid_actual:
                                hwnd_found = hwnd
                                return False  # encontrada, parar
                            return True

                        u32.EnumWindows(WNDENUMPROC(enum_cb), 0)

                        if not hwnd_found:
                            logger.warning("win32_icon: no se encontró ventana del proceso")
                            return

                        hicon_big = u32.LoadImageW(
                            0, str(ico_path), IMAGE_ICON, 48, 48,
                            LR_LOADFROMFILE)
                        hicon_sm = u32.LoadImageW(
                            0, str(ico_path), IMAGE_ICON, 16, 16,
                            LR_LOADFROMFILE)
                        if hicon_big:
                            u32.SendMessageW(hwnd_found, WM_SETICON, ICON_BIG, hicon_big)
                        if hicon_sm:
                            u32.SendMessageW(hwnd_found, WM_SETICON, ICON_SMALL, hicon_sm)
                        logger.info(f"win32_icon: icono aplicado a hwnd={hwnd_found}")
                    except Exception:
                        logger.exception("win32_icon")
                threading.Thread(target=_set_win_icon, daemon=True).start()
        except Exception:
            pass

        if self._skip_startup_checks:
            self._skip_startup_checks = False
        else:
            try: self._check_quincenal_alert()
            except Exception: logger.exception("alert")
            try: self._check_for_updates(manual=False)
            except Exception: logger.exception("auto_update_check")


def run_app():
    app = FinanzasFletApp()
    ft.app(target=app.main)


if __name__ == "__main__":
    freeze_support()
    run_app()
