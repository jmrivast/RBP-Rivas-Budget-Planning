"""
Funciones auxiliares para la aplicación.
"""
from datetime import datetime, date
from typing import Tuple
import logging

logger = logging.getLogger(__name__)


def get_quincenal_cycle(date_obj: date = None) -> int:
    """
    Detectar automáticamente el ciclo de quincena.
    
    Args:
        date_obj: Objeto datetime.date. Si es None, usa la fecha actual.
    
    Returns:
        1 si es quincena 1 (1-15), 2 si es quincena 2 (16-fin de mes)
    """
    if date_obj is None:
        date_obj = date.today()
    
    return 1 if date_obj.day <= 15 else 2


def get_year_month_from_date(date_str: str) -> Tuple[int, int]:
    """
    Extraer año y mes de una cadena de fecha.
    
    Args:
        date_str: Fecha en formato 'YYYY-MM-DD'
    
    Returns:
        Tupla (año, mes)
    """
    try:
        date_obj = datetime.strptime(date_str, "%Y-%m-%d").date()
        return date_obj.year, date_obj.month
    except ValueError:
        logger.error(f"Formato de fecha inválido: {date_str}")
        return None, None


def format_currency(amount: float, currency: str = "RD$") -> str:
    """
    Formatear un número como moneda.
    
    Args:
        amount: Cantidad a formatear
        currency: Símbolo de moneda
    
    Returns:
        Cadena formateada
    """
    return f"{currency}{amount:,.2f}"


def calculate_budget_percentage(spent: float, budget: float) -> float:
    """
    Calcular el porcentaje del presupuesto gastado.
    
    Args:
        spent: Monto gastado
        budget: Presupuesto total
    
    Returns:
        Porcentaje (0-100)
    """
    if budget == 0:
        return 0
    return (spent / budget) * 100


def get_budget_status_color(percentage: float) -> str:
    """
    Obtener el color del estado del presupuesto basado en el porcentaje.
    
    Args:
        percentage: Porcentaje del presupuesto gastado
    
    Returns:
        Color en formato hexadecimal
    """
    from src.config import SUCCESS_COLOR, WARNING_COLOR, DANGER_COLOR
    
    if percentage <= 50:
        return SUCCESS_COLOR  # Verde
    elif percentage <= 80:
        return WARNING_COLOR  # Naranja
    else:
        return DANGER_COLOR  # Rojo


def get_quincenal_range(year: int, month: int, quincenal_cycle: int) -> Tuple[str, str]:
    """
    Obtener el rango de fechas de una quincena.
    
    Args:
        year: Año
        month: Mes
        quincenal_cycle: Ciclo de quincena (1 o 2)
    
    Returns:
        Tupla (fecha_inicio, fecha_fin) en formato 'YYYY-MM-DD'
    """
    from calendar import monthrange
    
    _, last_day = monthrange(year, month)
    
    if quincenal_cycle == 1:
        start = f"{year}-{month:02d}-01"
        end = f"{year}-{month:02d}-15"
    else:
        start = f"{year}-{month:02d}-16"
        end = f"{year}-{month:02d}-{last_day:02d}"
    
    return start, end


def get_quincenal_label(year: int, month: int, quincenal_cycle: int) -> str:
    """
    Obtener una etiqueta descriptiva para una quincena.
    
    Args:
        year: Año
        month: Mes
        quincenal_cycle: Ciclo de quincena (1 o 2)
    
    Returns:
        Cadena descriptiva
    """
    months = {
        1: "Enero", 2: "Febrero", 3: "Marzo", 4: "Abril",
        5: "Mayo", 6: "Junio", 7: "Julio", 8: "Agosto",
        9: "Septiembre", 10: "Octubre", 11: "Noviembre", 12: "Diciembre"
    }
    
    cycle_label = "1ª Quincena" if quincenal_cycle == 1 else "2ª Quincena"
    return f"{cycle_label} - {months[month]} {year}"


def validate_email(email: str) -> bool:
    """
    Validar formato de email básico.
    
    Args:
        email: Dirección de email
    
    Returns:
        True si es válido, False en caso contrario
    """
    import re
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None


def validate_amount(amount_str: str) -> bool:
    """
    Validar que una cadena sea un número válido.
    
    Args:
        amount_str: Cadena a validar
    
    Returns:
        True si es válido, False en caso contrario
    """
    try:
        float(amount_str)
        return True
    except ValueError:
        return False


def format_date_to_display(date_str: str) -> str:
    """
    Formatear fecha para mostrar en UI.
    
    Args:
        date_str: Fecha en formato 'YYYY-MM-DD'
    
    Returns:
        Fecha formateada (ej: '11 de febrero de 2026')
    """
    try:
        date_obj = datetime.strptime(date_str, "%Y-%m-%d").date()
        months = {
            1: "enero", 2: "febrero", 3: "marzo", 4: "abril",
            5: "mayo", 6: "junio", 7: "julio", 8: "agosto",
            9: "septiembre", 10: "octubre", 11: "noviembre", 12: "diciembre"
        }
        return f"{date_obj.day} de {months[date_obj.month]} de {date_obj.year}"
    except ValueError:
        return date_str
