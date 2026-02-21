"""
Frame principal de login/selección de usuario.
"""
import customtkinter as ctk
from src.config import PRIMARY_COLOR, SECONDARY_COLOR
import logging

logger = logging.getLogger(__name__)


class MainFrame(ctk.CTkFrame):
    """Frame principal para login y selección de usuario."""
    
    def __init__(self, parent, app):
        super().__init__(parent)
        self.app = app
        self.setup_ui()
    
    def setup_ui(self):
        """Configurar la interfaz de usuario."""
        # Frame central
        central_frame = ctk.CTkFrame(self, fg_color="transparent")
        central_frame.pack(expand=True, padx=20, pady=20)
        
        # Título
        title = ctk.CTkLabel(
            central_frame,
            text="Gestor de Finanzas Personal",
            font=("Arial", 32, "bold"),
            text_color=PRIMARY_COLOR
        )
        title.pack(pady=20)
        
        subtitle = ctk.CTkLabel(
            central_frame,
            text="Meta de Ahorro: 45%",
            font=("Arial", 16),
            text_color="gray"
        )
        subtitle.pack(pady=10)
        
        # Sección de entrada de usuario
        input_frame = ctk.CTkFrame(central_frame, fg_color=PRIMARY_COLOR, corner_radius=10)
        input_frame.pack(pady=30, padx=20, fill="both", expand=True)
        
        label = ctk.CTkLabel(
            input_frame,
            text="Ingresa tu nombre de usuario:",
            font=("Arial", 14),
            text_color="white"
        )
        label.pack(pady=20)
        
        self.username_entry = ctk.CTkEntry(
            input_frame,
            placeholder_text="Tu nombre de usuario",
            width=300,
            font=("Arial", 12)
        )
        self.username_entry.pack(pady=10, padx=20)
        
        # Botones
        button_frame = ctk.CTkFrame(input_frame, fg_color="transparent")
        button_frame.pack(pady=20)
        
        login_btn = ctk.CTkButton(
            button_frame,
            text="Iniciar Sesión",
            command=self.login,
            fg_color=SECONDARY_COLOR,
            hover_color=PRIMARY_COLOR
        )
        login_btn.pack(side="left", padx=10)
        
        new_user_btn = ctk.CTkButton(
            button_frame,
            text="Crear Nuevo Usuario",
            command=self.create_new_user,
            fg_color=SECONDARY_COLOR,
            hover_color=PRIMARY_COLOR
        )
        new_user_btn.pack(side="left", padx=10)
        
        # Usuarios existentes
        users_label = ctk.CTkLabel(
            central_frame,
            text="Usuarios Existentes:",
            font=("Arial", 12, "bold")
        )
        users_label.pack(pady=10)
        
        self.refresh_users_list()
    
    def refresh_users_list(self):
        """Refrescar la lista de usuarios existentes."""
        self.app.db.connect()
        users = self.app.db.get_all_users()
        self.app.db.disconnect()
        
        if users:
            users_frame = ctk.CTkFrame(self)
            users_frame.pack(pady=10)
            
            for user in users:
                user_btn = ctk.CTkButton(
                    users_frame,
                    text=f"👤 {user['username']}",
                    command=lambda u_id=user['id']: self.select_user(u_id),
                    fg_color=SECONDARY_COLOR,
                    hover_color=PRIMARY_COLOR
                )
                user_btn.pack(pady=5, padx=20, fill="x")
    
    def login(self):
        """Intentar iniciar sesión con el usuario ingresado."""
        username = self.username_entry.get().strip()
        
        if not username:
            self.show_error("Por favor, ingresa un nombre de usuario")
            return
        
        self.app.db.connect()
        user = self.app.db.get_user_by_username(username)
        self.app.db.disconnect()
        
        if user:
            self.app.set_current_user(user['id'])
            logger.info(f"Usuario iniciado sesión: {username}")
        else:
            self.show_error(f"Usuario '{username}' no encontrado")
    
    def create_new_user(self):
        """Crear un nuevo usuario."""
        username = self.username_entry.get().strip()
        
        if not username:
            self.show_error("Por favor, ingresa un nombre de usuario")
            return
        
        self.app.db.connect()
        
        # Verificar si el usuario ya existe
        if self.app.db.get_user_by_username(username):
            self.show_error(f"El usuario '{username}' ya existe")
            self.app.db.disconnect()
            return
        
        # Crear usuario
        user_id = self.app.db.create_user(username)
        
        # Crear categorías por defecto
        from src.config import DEFAULT_CATEGORIES
        for category_name in DEFAULT_CATEGORIES:
            self.app.db.create_category(user_id, category_name)
        
        self.app.db.disconnect()
        
        logger.info(f"Nuevo usuario creado: {username}")
        self.username_entry.delete(0, "end")
        self.refresh_users_list()
        self.app.set_current_user(user_id)
    
    def select_user(self, user_id: int):
        """Seleccionar un usuario existente."""
        self.app.set_current_user(user_id)
    
    def show_error(self, message: str):
        """Mostrar un mensaje de error."""
        error_window = ctk.CTkToplevel(self)
        error_window.title("Error")
        error_window.geometry("300x100")
        
        label = ctk.CTkLabel(error_window, text=message, wraplength=250)
        label.pack(pady=20)
        
        btn = ctk.CTkButton(error_window, text="OK", command=error_window.destroy)
        btn.pack(pady=10)
