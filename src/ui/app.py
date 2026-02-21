"""
Archivo principal de la aplicación con CustomTkinter.
"""
import customtkinter as ctk
from pathlib import Path
import logging
from datetime import datetime

from src.config import *
from src.db.database import Database
from src.utils.backup import BackupManager
from src.ui.frames.main_frame import MainFrame
from src.ui.frames.dashboard_frame import DashboardFrame
from src.ui.frames.expenses_frame import ExpensesFrame
from src.ui.frames.fixed_payments_frame import FixedPaymentsFrame
from src.ui.frames.savings_frame import SavingsFrame
from src.ui.frames.settings_frame import SettingsFrame

# Configurar logging
logging.basicConfig(
    level=LOG_LEVEL,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class AppFinanzas(ctk.CTk):
    """Clase principal de la aplicación."""
    
    def __init__(self):
        super().__init__()
        
        # Configuración de la ventana
        self.title(APP_TITLE)
        self.geometry(f"{APP_WIDTH}x{APP_HEIGHT}")
        ctk.set_appearance_mode("dark")
        ctk.set_default_color_theme("blue")
        
        # Inicializar base de datos
        self.db = Database(DB_PATH)
        self.backup_manager = BackupManager(DB_PATH, BACKUP_DIR)
        
        # Variable para el usuario actual
        self.current_user_id = None
        
        # Crear interfaz de usuario
        self.setup_ui()
        
        # Crear respaldo automático
        self.backup_manager.create_backup()
        
        logger.info("Aplicación iniciada")
    
    def setup_ui(self):
        """Configurar la interfaz de usuario."""
        # Frame principal con navegación
        self.main_container = ctk.CTkFrame(self)
        self.main_container.pack(side="left", fill="both", expand=True)
        
        # Sidebar de navegación
        self.sidebar = ctk.CTkFrame(self, fg_color=PRIMARY_COLOR, width=200)
        self.sidebar.pack(side="right", fill="y", padx=0, pady=0)
        self.sidebar.pack_propagate(False)
        
        # Título del sidebar
        self.sidebar_title = ctk.CTkLabel(
            self.sidebar,
            text="FINANZAS",
            font=("Arial", 18, "bold"),
            text_color="white"
        )
        self.sidebar_title.pack(pady=20)
        
        # Botones de navegación
        self.nav_buttons = {}
        nav_items = [
            ("Dashboard", "dashboard"),
            ("Registrar Gasto", "expenses"),
            ("Pagos Fijos", "fixed_payments"),
            ("Ahorro", "savings"),
            ("Configuración", "settings")
        ]
        
        for label, key in nav_items:
            btn = ctk.CTkButton(
                self.sidebar,
                text=label,
                command=lambda k=key: self.show_frame(k),
                fg_color=SECONDARY_COLOR,
                hover_color=PRIMARY_COLOR,
                text_color="white"
            )
            btn.pack(pady=10, padx=10, fill="x")
            self.nav_buttons[key] = btn
        
        # Frame de contenido
        self.content_frame = ctk.CTkFrame(self.main_container, fg_color="transparent")
        self.content_frame.pack(fill="both", expand=True)
        
        # Frames de las pantallas
        self.frames = {}
        
        for F in (MainFrame, DashboardFrame, ExpensesFrame, FixedPaymentsFrame, SavingsFrame, SettingsFrame):
            frame = F(self.content_frame, self)
            self.frames[F.__name__.replace("Frame", "").lower()] = frame
            frame.grid(row=0, column=0, sticky="nsew")
        
        self.content_frame.grid_rowconfigure(0, weight=1)
        self.content_frame.grid_columnconfigure(0, weight=1)
        
        # Mostrar MainFrame inicialmente
        self.show_frame("main")
    
    def show_frame(self, name):
        """Mostrar un frame específico."""
        # Si no hay usuario seleccionado, mostrar MainFrame
        if name != "main" and not self.current_user_id:
            self.show_frame("main")
            return
        
        frame = self.frames.get(name)
        if frame:
            frame.tkraise()
            # Refrescar datos si es necesario
            if hasattr(frame, 'refresh_data'):
                frame.refresh_data()
    
    def set_current_user(self, user_id: int):
        """Establecer el usuario actual."""
        self.current_user_id = user_id
        self.show_frame("dashboard")
    
    def logout(self):
        """Cerrar sesión del usuario actual."""
        self.current_user_id = None
        self.show_frame("main")


if __name__ == "__main__":
    app = AppFinanzas()
    app.mainloop()
