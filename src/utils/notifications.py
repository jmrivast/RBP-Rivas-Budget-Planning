"""
Módulo para manejar notificaciones (email, etc).
"""
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import logging
from src.config import SMTP_SERVER, SMTP_PORT, EMAIL_SENDER, EMAIL_PASSWORD

logger = logging.getLogger(__name__)


class NotificationManager:
    """Clase para gestionar notificaciones."""
    
    def __init__(self):
        self.smtp_server = SMTP_SERVER
        self.smtp_port = SMTP_PORT
        self.sender_email = EMAIL_SENDER
        self.sender_password = EMAIL_PASSWORD
    
    def send_email(self, recipient_email: str, subject: str, body: str, is_html: bool = False) -> bool:
        """
        Enviar un email.
        
        Args:
            recipient_email: Email del destinatario
            subject: Asunto del email
            body: Cuerpo del email
            is_html: Si el cuerpo es HTML
        
        Returns:
            True si el email se envió exitosamente, False en caso contrario
        """
        try:
            if not self.sender_email or not self.sender_password:
                logger.warning("Credenciales de email no configuradas")
                return False
            
            message = MIMEMultipart("alternative")
            message["Subject"] = subject
            message["From"] = self.sender_email
            message["To"] = recipient_email
            
            mime_type = "html" if is_html else "plain"
            message.attach(MIMEText(body, mime_type))
            
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls()
                server.login(self.sender_email, self.sender_password)
                server.sendmail(self.sender_email, recipient_email, message.as_string())
            
            logger.info(f"Email enviado a {recipient_email}")
            return True
        
        except Exception as e:
            logger.error(f"Error al enviar email: {e}")
            return False
    
    def notify_pending_expenses(self, user_email: str, pending_count: int, total_amount: float) -> bool:
        """
        Notificar sobre gastos pendientes.
        
        Args:
            user_email: Email del usuario
            pending_count: Cantidad de gastos pendientes
            total_amount: Monto total pendiente
        
        Returns:
            True si la notificación se envió exitosamente
        """
        subject = "Recordatorio: Gastos Pendientes"
        body = f"""
        Tienes {pending_count} gasto(s) pendiente(s) por un total de RD${total_amount:,.2f}
        
        Por favor, ve a tu app de finanzas para marcarlos como completados.
        """
        return self.send_email(user_email, subject, body)
    
    def notify_budget_warning(self, user_email: str, category_name: str, spent: float, 
                             budget: float, percentage: float) -> bool:
        """
        Notificar sobre presupuesto que se está acabando.
        
        Args:
            user_email: Email del usuario
            category_name: Nombre de la categoría
            spent: Monto gastado
            budget: Presupuesto total
            percentage: Porcentaje gastado
        
        Returns:
            True si la notificación se envió exitosamente
        """
        subject = f"⚠️ Alerta de Presupuesto: {category_name}"
        body = f"""
        ¡Atención! Has gastado {percentage:.1f}% de tu presupuesto de {category_name}.
        
        Gastado: RD${spent:,.2f}
        Presupuesto: RD${budget:,.2f}
        Restante: RD${budget - spent:,.2f}
        """
        return self.send_email(user_email, subject, body)
    
    def notify_fixed_payment_due(self, user_email: str, payment_name: str, amount: float, due_day: int) -> bool:
        """
        Notificar sobre un pago fijo próximo.
        
        Args:
            user_email: Email del usuario
            payment_name: Nombre del pago
            amount: Monto del pago
            due_day: Día de vencimiento
        
        Returns:
            True si la notificación se envió exitosamente
        """
        subject = f"Recordatorio: {payment_name} vence pronto"
        body = f"""
        Tu pago fijo "{payment_name}" por RD${amount:,.2f} vence el día {due_day} del mes.
        
        No olvides marcarlo como pagado en tu app de finanzas.
        """
        return self.send_email(user_email, subject, body)
