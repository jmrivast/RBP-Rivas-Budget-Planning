"""
Módulo para manejar respaldos automáticos.
"""
import shutil
from pathlib import Path
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


class BackupManager:
    """Clase para gestionar respaldos de la base de datos."""
    
    def __init__(self, db_path: Path, backup_dir: Path):
        self.db_path = db_path
        self.backup_dir = backup_dir
        self.backup_dir.mkdir(exist_ok=True)
    
    def create_backup(self) -> bool:
        """
        Crear un respaldo de la base de datos.
        
        Returns:
            True si el respaldo fue exitoso, False en caso contrario
        """
        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_file = self.backup_dir / f"finanzas_backup_{timestamp}.db"
            shutil.copy2(self.db_path, backup_file)
            logger.info(f"Respaldo creado: {backup_file}")
            return True
        except Exception as e:
            logger.error(f"Error al crear respaldo: {e}")
            return False
    
    def get_latest_backup(self) -> Path:
        """
        Obtener el respaldo más reciente.
        
        Returns:
            Ruta del respaldo más reciente, o None si no hay respaldos
        """
        try:
            backups = sorted(self.backup_dir.glob("finanzas_backup_*.db"), 
                           key=lambda x: x.stat().st_mtime, reverse=True)
            return backups[0] if backups else None
        except Exception as e:
            logger.error(f"Error al obtener respaldo más reciente: {e}")
            return None
    
    def restore_backup(self, backup_file: Path) -> bool:
        """
        Restaurar una base de datos desde un respaldo.
        
        Args:
            backup_file: Ruta del archivo de respaldo
        
        Returns:
            True si la restauración fue exitosa, False en caso contrario
        """
        try:
            shutil.copy2(backup_file, self.db_path)
            logger.info(f"Base de datos restaurada desde: {backup_file}")
            return True
        except Exception as e:
            logger.error(f"Error al restaurar respaldo: {e}")
            return False
    
    def cleanup_old_backups(self, keep_count: int = 10):
        """
        Eliminar respaldos antiguos, manteniendo solo los más recientes.
        
        Args:
            keep_count: Número de respaldos recientes a mantener
        """
        try:
            backups = sorted(self.backup_dir.glob("finanzas_backup_*.db"), 
                           key=lambda x: x.stat().st_mtime, reverse=True)
            
            for backup in backups[keep_count:]:
                backup.unlink()
                logger.info(f"Respaldo antiguo eliminado: {backup}")
        except Exception as e:
            logger.error(f"Error al limpiar respaldos antiguos: {e}")
