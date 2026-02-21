"""
Frame para registrar gastos.
"""
import customtkinter as ctk
from datetime import datetime
from src.config import PRIMARY_COLOR, SECONDARY_COLOR, DANGER_COLOR
from src.utils.helpers import get_quincenal_cycle
import logging

logger = logging.getLogger(__name__)


class ExpensesFrame(ctk.CTkFrame):
    """Frame para registrar y gestionar gastos."""
    
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
            text="Registrar Gasto",
            font=("Arial", 24, "bold"),
            text_color="white"
        )
        title.pack(pady=15)
        
        # Formulario
        form_frame = ctk.CTkFrame(self, fg_color="transparent")
        form_frame.pack(fill="both", expand=True, padx=20, pady=20)
        
        # Monto
        monto_label = ctk.CTkLabel(form_frame, text="Monto (RD$):", font=("Arial", 12))
        monto_label.pack(pady=5)
        self.monto_entry = ctk.CTkEntry(form_frame, placeholder_text="0.00")
        self.monto_entry.pack(fill="x", pady=5)
        
        # Descripción
        desc_label = ctk.CTkLabel(form_frame, text="Descripción:", font=("Arial", 12))
        desc_label.pack(pady=5)
        self.desc_entry = ctk.CTkEntry(form_frame, placeholder_text="Ej: McDonald's")
        self.desc_entry.pack(fill="x", pady=5)
        
        # Fecha
        fecha_label = ctk.CTkLabel(form_frame, text="Fecha:", font=("Arial", 12))
        fecha_label.pack(pady=5)
        self.fecha_entry = ctk.CTkEntry(form_frame, placeholder_text="YYYY-MM-DD")
        self.fecha_entry.insert(0, datetime.now().strftime("%Y-%m-%d"))
        self.fecha_entry.pack(fill="x", pady=5)
        
        # Categorías (con checkboxes)
        cat_label = ctk.CTkLabel(form_frame, text="Categorías:", font=("Arial", 12, "bold"))
        cat_label.pack(pady=10)
        
        self.categories_frame = ctk.CTkScrollableFrame(form_frame, fg_color="#333")
        self.categories_frame.pack(fill="x", pady=5)
        
        self.category_checkboxes = {}
        self.refresh_categories()
        
        # Estado
        status_label = ctk.CTkLabel(form_frame, text="Estado:", font=("Arial", 12))
        status_label.pack(pady=5)
        self.status_menu = ctk.CTkOptionMenu(form_frame, values=["Pendiente", "Saldado"])
        self.status_menu.set("Saldado")
        self.status_menu.pack(fill="x", pady=5)
        
        # Botón guardar
        guardar_btn = ctk.CTkButton(
            form_frame,
            text="Guardar Gasto",
            command=self.guardar_gasto,
            fg_color=SECONDARY_COLOR,
            hover_color=PRIMARY_COLOR
        )
        guardar_btn.pack(pady=20, fill="x")
        
        # Lista de gastos recientes
        lista_label = ctk.CTkLabel(
            form_frame,
            text="Gastos Recientes:",
            font=("Arial", 12, "bold")
        )
        lista_label.pack(pady=10)
        
        self.gastos_frame = ctk.CTkScrollableFrame(form_frame, fg_color="#333", height=200)
        self.gastos_frame.pack(fill="both", expand=True, pady=5)
        
        self.refresh_data()
    
    def refresh_categories(self):
        """Refrescar lista de categorías."""
        if not self.app.current_user_id:
            return
        
        # Limpiar checkboxes
        for widget in self.categories_frame.winfo_children():
            widget.destroy()
        self.category_checkboxes.clear()
        
        # Obtener categorías
        self.app.db.connect()
        categories = self.app.db.get_categories_by_user(self.app.current_user_id)
        self.app.db.disconnect()
        
        for category in categories:
            var = ctk.BooleanVar(value=False)
            checkbox = ctk.CTkCheckBox(
                self.categories_frame,
                text=category['name'],
                variable=var
            )
            checkbox.pack(anchor="w", padx=10, pady=5)
            self.category_checkboxes[category['id']] = var
    
    def guardar_gasto(self):
        """Guardar un nuevo gasto."""
        if not self.app.current_user_id:
            return
        
        # Validar datos
        try:
            monto = float(self.monto_entry.get())
        except ValueError:
            self.show_error("Monto inválido")
            return
        
        desc = self.desc_entry.get().strip()
        if not desc:
            self.show_error("La descripción es obligatoria")
            return
        
        fecha = self.fecha_entry.get().strip()
        try:
            datetime.strptime(fecha, "%Y-%m-%d")
        except ValueError:
            self.show_error("Formato de fecha inválido (usar YYYY-MM-DD)")
            return
        
        # Obtener categorías seleccionadas
        category_ids = [cat_id for cat_id, var in self.category_checkboxes.items() if var.get()]
        if not category_ids:
            self.show_error("Selecciona al menos una categoría")
            return
        
        # Obtener estado
        status = "completed" if self.status_menu.get() == "Saldado" else "pending"
        
        # Obtener quincena
        from datetime import datetime
        fecha_obj = datetime.strptime(fecha, "%Y-%m-%d").date()
        quincenal_cycle = get_quincenal_cycle(fecha_obj)
        
        # Guardar gasto
        self.app.db.connect()
        try:
            self.app.db.create_expense(
                self.app.current_user_id,
                monto,
                desc,
                fecha,
                quincenal_cycle,
                category_ids,
                status
            )
            self.app.db.disconnect()
            
            # Limpiar formulario
            self.monto_entry.delete(0, "end")
            self.desc_entry.delete(0, "end")
            self.fecha_entry.delete(0, "end")
            self.fecha_entry.insert(0, datetime.now().strftime("%Y-%m-%d"))
            for var in self.category_checkboxes.values():
                var.set(False)
            
            self.show_success("Gasto registrado exitosamente")
            self.refresh_data()
        
        except Exception as e:
            logger.error(f"Error al guardar gasto: {e}")
            self.show_error("Error al guardar el gasto")
    
    def refresh_data(self):
        """Refrescar datos."""
        self.refresh_categories()
        self.refresh_gastos_list()
    
    def refresh_gastos_list(self):
        """Refrescar lista de gastos recientes."""
        if not self.app.current_user_id:
            return
        
        # Limpiar
        for widget in self.gastos_frame.winfo_children():
            widget.destroy()
        
        # Obtener gastos del mes actual
        self.app.db.connect()
        now = datetime.now()
        expenses = self.app.db.get_expenses_by_user_and_quincenal(
            self.app.current_user_id,
            now.year,
            now.month
        )
        self.app.db.disconnect()
        
        if not expenses:
            label = ctk.CTkLabel(self.gastos_frame, text="Sin gastos registrados", text_color="gray")
            label.pack(pady=10)
            return
        
        for expense in expenses[:10]:  # Mostrar últimos 10
            expense_widget = ctk.CTkFrame(self.gastos_frame, fg_color="#555", corner_radius=5)
            expense_widget.pack(fill="x", padx=5, pady=5)
            
            info_text = f"{expense['description']} - RD${expense['amount']:.2f} ({expense['date']}) [{expense['status']}]"
            label = ctk.CTkLabel(expense_widget, text=info_text, justify="left")
            label.pack(padx=10, pady=10, anchor="w")
    
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
