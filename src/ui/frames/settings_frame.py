"""
Frame de configuración.
"""
import customtkinter as ctk
from src.config import PRIMARY_COLOR, SECONDARY_COLOR
import logging

logger = logging.getLogger(__name__)


class SettingsFrame(ctk.CTkFrame):
    """Frame de configuración."""
    
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
            text="Configuración",
            font=("Arial", 24, "bold"),
            text_color="white"
        )
        title.pack(pady=15)
        
        # Contenido
        content_frame = ctk.CTkFrame(self, fg_color="transparent")
        content_frame.pack(fill="both", expand=True, padx=20, pady=20)
        
        # Sección de categorías
        cat_label = ctk.CTkLabel(
            content_frame,
            text="Gestionar Categorías",
            font=("Arial", 14, "bold")
        )
        cat_label.pack(pady=10)
        
        self.categories_frame = ctk.CTkScrollableFrame(content_frame, fg_color="#333", height=200)
        self.categories_frame.pack(fill="x", pady=10)
        
        # Botón para agregar categoría
        add_cat_btn = ctk.CTkButton(
            content_frame,
            text="+ Agregar Categoría",
            command=self.add_category,
            fg_color=SECONDARY_COLOR
        )
        add_cat_btn.pack(pady=10)
        
        # Botón para hacer respaldo
        backup_btn = ctk.CTkButton(
            content_frame,
            text="Hacer Respaldo",
            command=self.make_backup,
            fg_color=SECONDARY_COLOR
        )
        backup_btn.pack(pady=5, fill="x")
        
        # Botón para cerrar sesión
        logout_btn = ctk.CTkButton(
            content_frame,
            text="Cerrar Sesión",
            command=self.logout,
            fg_color="#FF4136"
        )
        logout_btn.pack(pady=5, fill="x")
        
        self.refresh_data()
    
    def refresh_data(self):
        """Refrescar datos."""
        self.refresh_categories()
    
    def refresh_categories(self):
        """Refrescar lista de categorías."""
        if not self.app.current_user_id:
            return
        
        # Limpiar
        for widget in self.categories_frame.winfo_children():
            widget.destroy()
        
        # Obtener categorías
        self.app.db.connect()
        categories = self.app.db.get_categories_by_user(self.app.current_user_id)
        self.app.db.disconnect()
        
        for category in categories:
            cat_widget = ctk.CTkFrame(self.categories_frame, fg_color="#555", corner_radius=5)
            cat_widget.pack(fill="x", padx=10, pady=5)
            
            label = ctk.CTkLabel(cat_widget, text=category['name'])
            label.pack(side="left", padx=10, pady=10)
            
            # Botón eliminar
            delete_btn = ctk.CTkButton(
                cat_widget,
                text="Eliminar",
                command=lambda c_id=category['id']: self.delete_category(c_id),
                fg_color="#FF4136",
                width=80
            )
            delete_btn.pack(side="right", padx=10)
    
    def add_category(self):
        """Agregar una nueva categoría."""
        # Ventana de diálogo
        dialog = ctk.CTkToplevel(self)
        dialog.title("Agregar Categoría")
        dialog.geometry("300x150")
        
        label = ctk.CTkLabel(dialog, text="Nombre de la categoría:")
        label.pack(pady=10)
        
        entry = ctk.CTkEntry(dialog)
        entry.pack(pady=5, padx=20, fill="x")
        
        def save_category():
            name = entry.get().strip()
            if not name:
                return
            
            self.app.db.connect()
            try:
                self.app.db.create_category(self.app.current_user_id, name)
                self.app.db.disconnect()
                dialog.destroy()
                self.refresh_data()
            except Exception as e:
                logger.error(f"Error al agregar categoría: {e}")
        
        btn = ctk.CTkButton(dialog, text="Guardar", command=save_category)
        btn.pack(pady=10)
    
    def delete_category(self, category_id: int):
        """Eliminar una categoría."""
        self.app.db.connect()
        try:
            self.app.db.delete_category(category_id)
            self.app.db.disconnect()
            self.refresh_data()
        except Exception as e:
            logger.error(f"Error al eliminar categoría: {e}")
    
    def make_backup(self):
        """Hacer un respaldo de la base de datos."""
        if self.app.backup_manager.create_backup():
            self.show_message("Respaldo creado exitosamente", "success")
        else:
            self.show_message("Error al crear respaldo", "error")
    
    def logout(self):
        """Cerrar sesión."""
        self.app.logout()
    
    def show_message(self, message: str, msg_type: str = "info"):
        """Mostrar un mensaje."""
        msg_window = ctk.CTkToplevel(self)
        msg_window.title("Mensaje")
        msg_window.geometry("300x100")
        
        color = "#2ECC40" if msg_type == "success" else "#FF4136"
        label = ctk.CTkLabel(msg_window, text=message, wraplength=250, text_color=color)
        label.pack(pady=20)
        
        btn = ctk.CTkButton(msg_window, text="OK", command=msg_window.destroy)
        btn.pack(pady=10)
