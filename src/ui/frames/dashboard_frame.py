"""
Frame del Dashboard - visualización principal de presupuestos y gastos.
"""
import customtkinter as ctk
from datetime import datetime, date
from src.config import PRIMARY_COLOR, SECONDARY_COLOR, SUCCESS_COLOR, WARNING_COLOR, DANGER_COLOR
from src.utils.helpers import (
    get_quincenal_cycle, get_year_month_from_date, calculate_budget_percentage,
    get_budget_status_color, format_currency, get_quincenal_label
)
import logging

logger = logging.getLogger(__name__)


class DashboardFrame(ctk.CTkFrame):
    """Frame del Dashboard."""
    
    def __init__(self, parent, app):
        super().__init__(parent)
        self.app = app
        self.current_quincenal_cycle = get_quincenal_cycle()
        self.current_year = datetime.now().year
        self.current_month = datetime.now().month
        self.setup_ui()
    
    def setup_ui(self):
        """Configurar la interfaz de usuario."""
        # Header
        header_frame = ctk.CTkFrame(self, fg_color=PRIMARY_COLOR)
        header_frame.pack(fill="x", padx=0, pady=0)
        
        title = ctk.CTkLabel(
            header_frame,
            text="Dashboard",
            font=("Arial", 24, "bold"),
            text_color="white"
        )
        title.pack(pady=15)
        
        # Información de quincena
        info_frame = ctk.CTkFrame(self, fg_color="transparent")
        info_frame.pack(fill="x", padx=20, pady=10)
        
        self.quincenal_label = ctk.CTkLabel(
            info_frame,
            text="",
            font=("Arial", 14, "bold"),
            text_color=PRIMARY_COLOR
        )
        self.quincenal_label.pack()
        
        # Navegación de quincena
        nav_frame = ctk.CTkFrame(info_frame, fg_color="transparent")
        nav_frame.pack(fill="x", pady=10)
        
        prev_btn = ctk.CTkButton(
            nav_frame,
            text="← Anterior",
            command=self.prev_quincenal,
            width=100
        )
        prev_btn.pack(side="left", padx=10)
        
        next_btn = ctk.CTkButton(
            nav_frame,
            text="Siguiente →",
            command=self.next_quincenal,
            width=100
        )
        next_btn.pack(side="left", padx=10)
        
        # Scroll frame para presupuestos
        scroll_frame = ctk.CTkScrollableFrame(self, fg_color="transparent")
        scroll_frame.pack(fill="both", expand=True, padx=20, pady=10)
        
        self.budgets_container = scroll_frame
        
        # Información de ahorro
        savings_frame = ctk.CTkFrame(self, fg_color=SECONDARY_COLOR, corner_radius=10)
        savings_frame.pack(fill="x", padx=20, pady=10)
        
        savings_title = ctk.CTkLabel(
            savings_frame,
            text="Ahorro Acumulado",
            font=("Arial", 14, "bold"),
            text_color="white"
        )
        savings_title.pack(pady=5)
        
        self.savings_label = ctk.CTkLabel(
            savings_frame,
            text="RD$0.00",
            font=("Arial", 20, "bold"),
            text_color="#2ECC40"
        )
        self.savings_label.pack(pady=10)
        
        # Información de disponible
        available_frame = ctk.CTkFrame(self, fg_color="#444", corner_radius=10)
        available_frame.pack(fill="x", padx=20, pady=10)
        
        available_title = ctk.CTkLabel(
            available_frame,
            text="Disponible para Gastar",
            font=("Arial", 12, "bold"),
            text_color="white"
        )
        available_title.pack(pady=5)
        
        self.available_label = ctk.CTkLabel(
            available_frame,
            text="RD$0.00",
            font=("Arial", 16, "bold"),
            text_color=SUCCESS_COLOR
        )
        self.available_label.pack(pady=10)
        
        self.refresh_data()
    
    def refresh_data(self):
        """Refrescar datos del dashboard."""
        if not self.app.current_user_id:
            return
        
        # Actualizar etiqueta de quincena
        self.quincenal_label.configure(
            text=get_quincenal_label(self.current_year, self.current_month, self.current_quincenal_cycle)
        )
        
        # Limpiar contenedor
        for widget in self.budgets_container.winfo_children():
            widget.destroy()
        
        # Obtener categorías y presupuestos
        self.app.db.connect()
        categories = self.app.db.get_categories_by_user(self.app.current_user_id)
        
        total_budget = 0
        total_spent = 0
        total_available = 0
        
        for category in categories:
            category_id = category['id']
            category_name = category['name']
            
            # Obtener presupuesto
            budget_amount = self.app.db.get_budget(
                self.app.current_user_id, category_id,
                self.current_quincenal_cycle, self.current_year, self.current_month
            )
            
            if budget_amount is None:
                # Usar presupuesto por defecto si existe
                from src.config import DEFAULT_BUDGETS
                budget_amount = DEFAULT_BUDGETS.get(category_name, 0)
            
            # Obtener gastos de la categoría
            expenses = self.app.db.get_expenses_by_user_and_quincenal(
                self.app.current_user_id, self.current_year, self.current_month,
                self.current_quincenal_cycle
            )
            
            # Sumar gastos saldados de esta categoría
            spent = 0
            for expense in expenses:
                if expense['status'] == 'completed':
                    category_ids = expense['category_ids'].split(',') if expense['category_ids'] else []
                    if str(category_id) in category_ids:
                        spent += expense['amount']
            
            total_budget += budget_amount
            total_spent += spent
            
            # Crear card para la categoría
            self.create_budget_card(category_name, spent, budget_amount)
        
        # Calcular disponible
        total_available = total_budget - total_spent
        
        # Actualizar etiquetas
        self.available_label.configure(text=format_currency(total_available))
        
        # Obtener ahorro acumulado
        total_savings = self.app.db.get_total_savings(self.app.current_user_id)
        self.savings_label.configure(text=format_currency(total_savings))
        
        self.app.db.disconnect()
    
    def create_budget_card(self, category_name: str, spent: float, budget: float):
        """Crear una tarjeta de presupuesto para una categoría."""
        card_frame = ctk.CTkFrame(self.budgets_container, fg_color="#333", corner_radius=10)
        card_frame.pack(fill="x", pady=10)
        
        # Header de la categoría
        header = ctk.CTkFrame(card_frame, fg_color="transparent")
        header.pack(fill="x", padx=15, pady=(10, 5))
        
        category_label = ctk.CTkLabel(
            header,
            text=category_name,
            font=("Arial", 12, "bold")
        )
        category_label.pack(side="left")
        
        amount_label = ctk.CTkLabel(
            header,
            text=f"{format_currency(spent)} / {format_currency(budget)}",
            font=("Arial", 11)
        )
        amount_label.pack(side="right")
        
        # Barra de progreso
        percentage = calculate_budget_percentage(spent, budget)
        color = get_budget_status_color(percentage)
        
        progress_frame = ctk.CTkFrame(card_frame, fg_color="#555", corner_radius=5)
        progress_frame.pack(fill="x", padx=15, pady=5)
        
        progress_width = int((percentage / 100) * 300) if percentage < 100 else 300
        progress_bar = ctk.CTkFrame(progress_frame, fg_color=color, corner_radius=5, width=progress_width, height=20)
        progress_bar.pack(side="left", fill="y")
        
        # Porcentaje
        percentage_label = ctk.CTkLabel(
            card_frame,
            text=f"{percentage:.1f}%",
            font=("Arial", 10)
        )
        percentage_label.pack(pady=(0, 10))
    
    def prev_quincenal(self):
        """Ir a la quincena anterior."""
        if self.current_quincenal_cycle == 1:
            self.current_quincenal_cycle = 2
            # Ir al mes anterior
            if self.current_month == 1:
                self.current_month = 12
                self.current_year -= 1
            else:
                self.current_month -= 1
        else:
            self.current_quincenal_cycle = 1
        
        self.refresh_data()
    
    def next_quincenal(self):
        """Ir a la quincena siguiente."""
        if self.current_quincenal_cycle == 1:
            self.current_quincenal_cycle = 2
        else:
            self.current_quincenal_cycle = 1
            # Ir al mes siguiente
            if self.current_month == 12:
                self.current_month = 1
                self.current_year += 1
            else:
                self.current_month += 1
        
        self.refresh_data()
