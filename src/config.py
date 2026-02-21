"""
Configuración centralizada de la aplicación.
"""
import os
import sys
from pathlib import Path

# Directorios base
if getattr(sys, "frozen", False):
    BASE_DIR = Path(sys.executable).resolve().parent
else:
    BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"
BACKUP_DIR = BASE_DIR / "backups"

# Crear directorios si no existen
DATA_DIR.mkdir(exist_ok=True)
BACKUP_DIR.mkdir(exist_ok=True)

# Base de datos
DB_PATH = DATA_DIR / "finanzas.db"

# Configuración de UI
APP_TITLE = "Gestor de Finanzas Personal 45%"
APP_WIDTH = 1200
APP_HEIGHT = 800
PRIMARY_COLOR = "#001F3F"  # Azul marino
SECONDARY_COLOR = "#0074D9"  # Azul más claro
SUCCESS_COLOR = "#2ECC40"  # Verde
WARNING_COLOR = "#FF851B"  # Naranja
DANGER_COLOR = "#FF4136"  # Rojo

# Categorías por defecto
DEFAULT_CATEGORIES = [
    "Comida",
    "Combustible",
    "Uber/Taxi",
    "Subscripciones",
    "Varios/Snacks",
    "Otros"
]

# Presupuestos por defecto (en RD$)
DEFAULT_BUDGETS = {
    "Comida": 2750,
    "Combustible": 3500,
    "Uber/Taxi": 1000,
    "Subscripciones": 1300,
    "Varios/Snacks": 529,
}

# Ahorro automático
AUTOMATIC_SAVINGS_AMOUNT = 7500

# Ciclo de quincena
FIRST_QUINCENAL_END = 15
SECOND_QUINCENAL_START = 16

# Email (para notificaciones)
SMTP_SERVER = os.getenv("SMTP_SERVER", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
EMAIL_SENDER = os.getenv("EMAIL_SENDER", "")
EMAIL_PASSWORD = os.getenv("EMAIL_PASSWORD", "")

# Respaldos automáticos
AUTO_BACKUP_ENABLED = True
AUTO_BACKUP_INTERVAL_MINUTES = 60

# Logging
LOG_LEVEL = "INFO"
