"""
Frame para visualizar y gestionar ahorros.
"""
import customtkinter as ctk
from src.config import PRIMARY_COLOR, SECONDARY_COLOR
from src.utils.helpers import format_currency
import logging

logger = logging.getLogger(__name__)


class SavingsFrame(ctk.CTkFrame):
    """Frame para visualizar ahorros acumulados."""
    
    def __init__(self, parent, app):
        super().__init__(parent)
        self.app = app
        self.setup_ui()
    
    def setup_ui(self):
        """Configurar la interfaz de usuario."""
        # Header
        header_frame = ctk.CTkFrame(self, fg_color=PRIMARY_COLOR)
        header_frame.pack(fill="x", padx=0, pady=0)
        
        title = ctk.CTkLabel(
            header_frame,
            text="Mi Ahorro",
            font=("Arial", 24, "bold"),
            text_color="white"
        )
        title.pack(pady=15)
        
        # Tarjeta de ahorro total
        total_frame = ctk.CTkFrame(self, fg_color=SECONDARY_COLOR, corner_radius=15)
        total_frame.pack(fill="x", padx=20, pady=20)
        
        total_label = ctk.CTkLabel(
            total_frame,
            text="Ahorro Total Acumulado",
            font=("Arial", 16, "bold"),
            text_color="white"
        )
        total_label.pack(pady=(15, 5))
        
        self.total_savings_label = ctk.CTkLabel(
            total_frame,
            text="RD$0.00",
            font=("Arial", 32, "bold"),
            text_color="#2ECC40"
        )
        self.total_savings_label.pack(pady=(5, 15))
        
        # Información de meta
        meta_frame = ctk.CTkFrame(self, fg_color="#333", corner_radius=10)
        meta_frame.pack(fill="x", padx=20, pady=10)
        
        meta_label = ctk.CTkLabel(
            meta_frame,
            text="Meta de Ahorro: 45% del Salario",
            font=("Arial", 14, "bold")
        )
        meta_label.pack(pady=10)
        
        meta_info = ctk.CTkLabel(
            meta_frame,
            text="RD$7,500 por quincena",
            font=("Arial", 12),
            text_color="gray"
        )
        meta_info.pack(pady=(0, 10))
        
        # Historial de ahorros
        historial_label = ctk.CTkLabel(
            self,
            text="Historial de Ahorros:",
            font=("Arial", 14, "bold")
        )
        historial_label.pack(pady=10)
        
        self.historial_frame = ctk.CTkScrollableFrame(self, fg_color="transparent")
        self.historial_frame.pack(fill="both", expand=True, padx=20, pady=10)
        
        self.refresh_data()
    
    def refresh_data(self):
        """Refrescar datos de ahorros."""
        if not self.app.current_user_id:
            return
        
        # Obtener ahorro total
        self.app.db.connect()
        total_savings = self.app.db.get_total_savings(self.app.current_user_id)
        self.app.db.disconnect()
        
        self.total_savings_label.configure(text=format_currency(total_savings))
        
        # Limpiar historial
        for widget in self.historial_frame.winfo_children():
            widget.destroy()
        
        # Mostrar mensaje si no hay ahorros
        if total_savings == 0:
            label = ctk.CTkLabel(
                self.historial_frame,
                text="Aún no hay registros de ahorro",
                text_color="gray"
            )
            label.pack(pady=20)
