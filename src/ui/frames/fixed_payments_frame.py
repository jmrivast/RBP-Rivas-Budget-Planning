"""
Frame para gestionar pagos fijos/subscripciones.
"""
import customtkinter as ctk
from src.config import PRIMARY_COLOR, SECONDARY_COLOR, DANGER_COLOR
import logging

logger = logging.getLogger(__name__)


class FixedPaymentsFrame(ctk.CTkFrame):
    """Frame para gestionar pagos fijos y subscripciones."""
    
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
            text="Pagos Fijos & Subscripciones",
            font=("Arial", 24, "bold"),
            text_color="white"
        )
        title.pack(pady=15)
        
        # Formulario para agregar pago fijo
        form_frame = ctk.CTkFrame(self, fg_color=PRIMARY_COLOR, corner_radius=10)
        form_frame.pack(fill="x", padx=20, pady=20)
        
        form_title = ctk.CTkLabel(
            form_frame,
            text="Agregar Nuevo Pago Fijo",
            font=("Arial", 14, "bold"),
            text_color="white"
        )
        form_title.pack(pady=10)
        
        # Nombre
        name_label = ctk.CTkLabel(form_frame, text="Nombre:", font=("Arial", 11), text_color="white")
        name_label.pack(pady=5)
        self.name_entry = ctk.CTkEntry(form_frame, placeholder_text="Ej: Netflix")
        self.name_entry.pack(fill="x", padx=15, pady=5)
        
        # Monto
        amount_label = ctk.CTkLabel(form_frame, text="Monto (RD$):", font=("Arial", 11), text_color="white")
        amount_label.pack(pady=5)
        self.amount_entry = ctk.CTkEntry(form_frame, placeholder_text="0.00")
        self.amount_entry.pack(fill="x", padx=15, pady=5)
        
        # Día de vencimiento
        day_label = ctk.CTkLabel(form_frame, text="Día de Vencimiento:", font=("Arial", 11), text_color="white")
        day_label.pack(pady=5)
        self.day_entry = ctk.CTkEntry(form_frame, placeholder_text="Ej: 15")
        self.day_entry.pack(fill="x", padx=15, pady=5)
        
        # Categoría
        cat_label = ctk.CTkLabel(form_frame, text="Categoría (opcional):", font=("Arial", 11), text_color="white")
        cat_label.pack(pady=5)
        self.category_menu = ctk.CTkOptionMenu(form_frame, values=["Ninguna"])
        self.category_menu.pack(fill="x", padx=15, pady=5)
        self.refresh_categories()
        
        # Botón agregar
        add_btn = ctk.CTkButton(
            form_frame,
            text="Agregar Pago Fijo",
            command=self.agregar_pago,
            fg_color=SECONDARY_COLOR
        )
        add_btn.pack(pady=15)
        
        # Lista de pagos fijos
        lista_label = ctk.CTkLabel(
            self,
            text="Pagos Fijos Activos:",
            font=("Arial", 14, "bold")
        )
        lista_label.pack(pady=10)
        
        self.pagos_frame = ctk.CTkScrollableFrame(self, fg_color="transparent")
        self.pagos_frame.pack(fill="both", expand=True, padx=20, pady=10)
        
        self.refresh_data()
    
    def refresh_categories(self):
        """Refrescar categorías disponibles."""
        if not self.app.current_user_id:
            return
        
        self.app.db.connect()
        categories = self.app.db.get_categories_by_user(self.app.current_user_id)
        self.app.db.disconnect()
        
        cat_names = ["Ninguna"] + [cat['name'] for cat in categories]
        self.category_menu.configure(values=cat_names)
        self.category_menu.set("Ninguna")
    
    def agregar_pago(self):
        """Agregar un nuevo pago fijo."""
        if not self.app.current_user_id:
            return
        
        # Validar datos
        name = self.name_entry.get().strip()
        if not name:
            self.show_error("El nombre es obligatorio")
            return
        
        try:
            amount = float(self.amount_entry.get())
        except ValueError:
            self.show_error("Monto inválido")
            return
        
        try:
            due_day = int(self.day_entry.get())
            if due_day < 1 or due_day > 31:
                raise ValueError
        except ValueError:
            self.show_error("Día debe estar entre 1 y 31")
            return
        
        # Obtener categoría
        category_id = None
        if self.category_menu.get() != "Ninguna":
            self.app.db.connect()
            categories = self.app.db.get_categories_by_user(self.app.current_user_id)
            for cat in categories:
                if cat['name'] == self.category_menu.get():
                    category_id = cat['id']
                    break
            self.app.db.disconnect()
        
        # Guardar pago fijo
        self.app.db.connect()
        try:
            self.app.db.create_fixed_payment(
                self.app.current_user_id,
                name,
                amount,
                due_day,
                category_id
            )
            self.app.db.disconnect()
            
            # Limpiar formulario
            self.name_entry.delete(0, "end")
            self.amount_entry.delete(0, "end")
            self.day_entry.delete(0, "end")
            self.category_menu.set("Ninguna")
            
            self.show_success("Pago fijo agregado exitosamente")
            self.refresh_data()
        
        except Exception as e:
            logger.error(f"Error al agregar pago fijo: {e}")
            self.show_error("Error al agregar el pago fijo")
    
    def refresh_data(self):
        """Refrescar datos."""
        self.refresh_categories()
        self.refresh_pagos_list()
    
    def refresh_pagos_list(self):
        """Refrescar lista de pagos fijos."""
        if not self.app.current_user_id:
            return
        
        # Limpiar
        for widget in self.pagos_frame.winfo_children():
            widget.destroy()
        
        # Obtener pagos fijos
        self.app.db.connect()
        pagos = self.app.db.get_fixed_payments_by_user(self.app.current_user_id)
        self.app.db.disconnect()
        
        if not pagos:
            label = ctk.CTkLabel(self.pagos_frame, text="Sin pagos fijos registrados", text_color="gray")
            label.pack(pady=10)
            return
        
        for pago in pagos:
            pago_widget = ctk.CTkFrame(self.pagos_frame, fg_color="#333", corner_radius=10)
            pago_widget.pack(fill="x", padx=0, pady=10)
            
            # Info
            info_frame = ctk.CTkFrame(pago_widget, fg_color="transparent")
            info_frame.pack(fill="x", padx=15, pady=(10, 5))
            
            name_label = ctk.CTkLabel(
                info_frame,
                text=f"{pago['name']} - RD${pago['amount']:.2f}",
                font=("Arial", 12, "bold")
            )
            name_label.pack(side="left")
            
            day_label = ctk.CTkLabel(
                info_frame,
                text=f"Vence: día {pago['due_day']}",
                font=("Arial", 11)
            )
            day_label.pack(side="right")
            
            # Botones
            button_frame = ctk.CTkFrame(pago_widget, fg_color="transparent")
            button_frame.pack(fill="x", padx=15, pady=(5, 10))
            
            delete_btn = ctk.CTkButton(
                button_frame,
                text="Eliminar",
                command=lambda p_id=pago['id']: self.eliminar_pago(p_id),
                fg_color=DANGER_COLOR,
                width=80
            )
            delete_btn.pack(side="right")
    
    def eliminar_pago(self, pago_id: int):
        """Eliminar un pago fijo."""
        self.app.db.connect()
        try:
            self.app.db.delete_fixed_payment(pago_id)
            self.app.db.disconnect()
            self.show_success("Pago fijo eliminado")
            self.refresh_data()
        except Exception as e:
            logger.error(f"Error al eliminar pago fijo: {e}")
            self.show_error("Error al eliminar el pago")
    
    def show_error(self, message: str):
        """Mostrar mensaje de error."""
        error_window = ctk.CTkToplevel(self)
        error_window.title("Error")
        error_window.geometry("300x100")
        
        label = ctk.CTkLabel(error_window, text=message, wraplength=250)
        label.pack(pady=20)
        
        btn = ctk.CTkButton(error_window, text="OK", command=error_window.destroy)
        btn.pack(pady=10)
    
    def show_success(self, message: str):
        """Mostrar mensaje de éxito."""
        success_window = ctk.CTkToplevel(self)
        success_window.title("Éxito")
        success_window.geometry("300x100")
        
        label = ctk.CTkLabel(success_window, text=message, wraplength=250, text_color="#2ECC40")
        label.pack(pady=20)
        
        btn = ctk.CTkButton(success_window, text="OK", command=success_window.destroy)
        btn.pack(pady=10)
