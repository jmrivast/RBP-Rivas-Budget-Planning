"""
Módulo de base de datos con SQLite.
Maneja todas las operaciones CRUD y consultas.
"""
import sqlite3
from calendar import monthrange
from datetime import datetime
from pathlib import Path
import json
from typing import List, Dict, Optional, Tuple
import logging

logger = logging.getLogger(__name__)


class Database:
    """Clase para manejar todas las operaciones de base de datos."""
    
    def __init__(self, db_path: Path):
        self.db_path = db_path
        self.connection = None
        self.init_db()
    
    def connect(self):
        """Conectar a la base de datos."""
        try:
            if self.connection is not None:
                try:
                    self.connection.execute("SELECT 1")
                    return
                except sqlite3.Error:
                    try:
                        self.connection.close()
                    except sqlite3.Error:
                        pass
                    self.connection = None
            self.connection = sqlite3.connect(str(self.db_path), check_same_thread=False)
            self.connection.row_factory = sqlite3.Row
            logger.info(f"Conectado a la base de datos: {self.db_path}")
        except sqlite3.Error as e:
            logger.error(f"Error al conectar a la base de datos: {e}")
            raise
    
    def disconnect(self):
        """Desconectar de la base de datos."""
        if self.connection:
            self.connection.close()
            self.connection = None
            logger.info("Desconectado de la base de datos")
    
    def execute(self, query: str, params: tuple = ()) -> sqlite3.Cursor:
        """Ejecutar una consulta."""
        if not self.connection:
            self.connect()
        cursor = self.connection.cursor()
        cursor.execute(query, params)
        return cursor
    
    def commit(self):
        """Confirmar cambios."""
        if self.connection:
            self.connection.commit()
    
    def init_db(self):
        """Inicializar la base de datos con las tablas necesarias."""
        self.connect()
        cursor = self.connection.cursor()
        
        # Tabla de usuarios
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                email TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                is_active BOOLEAN DEFAULT 1
            )
        ''')
        
        # Tabla de categorías
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS categories (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                name TEXT NOT NULL,
                color TEXT,
                icon TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id),
                UNIQUE(user_id, name)
            )
        ''')
        
        # Tabla de presupuestos por categoría y quincena
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS budgets (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                category_id INTEGER NOT NULL,
                amount REAL NOT NULL,
                quincenal_cycle INTEGER NOT NULL,
                year INTEGER NOT NULL,
                month INTEGER NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id),
                FOREIGN KEY (category_id) REFERENCES categories(id),
                UNIQUE(user_id, category_id, quincenal_cycle, year, month)
            )
        ''')
        
        # Tabla de gastos
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS expenses (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                amount REAL NOT NULL,
                description TEXT NOT NULL,
                date DATE NOT NULL,
                quincenal_cycle INTEGER NOT NULL,
                status TEXT DEFAULT 'pending',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        ''')
        
        # Tabla de relación gastos-categorías (multi-categoría)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS expense_categories (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                expense_id INTEGER NOT NULL,
                category_id INTEGER NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE,
                FOREIGN KEY (category_id) REFERENCES categories(id),
                UNIQUE(expense_id, category_id)
            )
        ''')
        
        # Tabla de pagos fijos/subscripciones
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS fixed_payments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                name TEXT NOT NULL,
                amount REAL NOT NULL,
                category_id INTEGER,
                due_day INTEGER NOT NULL,
                frequency TEXT DEFAULT 'monthly',
                is_active BOOLEAN DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id),
                FOREIGN KEY (category_id) REFERENCES categories(id)
            )
        ''')
        
        # Tabla de registro de pagos fijos (para saber si ya se pagaron)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS fixed_payment_records (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                fixed_payment_id INTEGER NOT NULL,
                expense_id INTEGER,
                year INTEGER NOT NULL,
                month INTEGER NOT NULL,
                quincenal_cycle INTEGER,
                status TEXT DEFAULT 'pending',
                paid_date DATE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (fixed_payment_id) REFERENCES fixed_payments(id),
                FOREIGN KEY (expense_id) REFERENCES expenses(id)
            )
        ''')
        
        # Tabla de ingresos extras
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS extra_income (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                amount REAL NOT NULL,
                description TEXT NOT NULL,
                date DATE NOT NULL,
                income_type TEXT DEFAULT 'bonus',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        ''')
        
        # Tabla de ahorro acumulado
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS savings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                total_saved REAL DEFAULT 0,
                last_quincenal_savings REAL,
                year INTEGER NOT NULL,
                month INTEGER NOT NULL,
                quincenal_cycle INTEGER NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id),
                UNIQUE(user_id, year, month, quincenal_cycle)
            )
        ''')
        
        # Tabla de respaldos
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS backups (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                backup_file TEXT NOT NULL,
                backup_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        ''')

        # Tabla de préstamos
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS loans (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                person TEXT NOT NULL,
                amount REAL NOT NULL,
                description TEXT,
                date DATE NOT NULL,
                is_paid BOOLEAN DEFAULT 0,
                paid_date DATE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        ''')

        # Migration: agregar deduction_type a loans
        try:
            cursor.execute("ALTER TABLE loans ADD COLUMN deduction_type TEXT DEFAULT 'ninguno'")
        except Exception:
            pass

        # Tabla de metas de ahorro
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS savings_goals (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                name TEXT NOT NULL,
                target_amount REAL NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        ''')

        # Tabla de salario del usuario
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS user_salary (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL UNIQUE,
                amount REAL NOT NULL DEFAULT 0,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        ''')

        # Tabla de salario específico por quincena (override opcional)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS salary_overrides (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                year INTEGER NOT NULL,
                month INTEGER NOT NULL,
                cycle INTEGER NOT NULL,
                amount REAL NOT NULL,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id),
                UNIQUE(user_id, year, month, cycle)
            )
        ''')

        # Preferencias de período (quincenal / mensual)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS user_period_mode (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL UNIQUE,
                mode TEXT NOT NULL DEFAULT 'quincenal',
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        ''')

        # Configuraciones varias por usuario (clave/valor)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS user_settings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                setting_key TEXT NOT NULL,
                setting_value TEXT NOT NULL,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id),
                UNIQUE(user_id, setting_key)
            )
        ''')

        # Tabla de quincenas personalizadas
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS custom_quincena (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                year INTEGER NOT NULL,
                month INTEGER NOT NULL,
                cycle INTEGER NOT NULL,
                start_date TEXT NOT NULL,
                end_date TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id),
                UNIQUE(user_id, year, month, cycle)
            )
        ''')

        self.connection.commit()
        logger.info("Base de datos inicializada correctamente")
        self.disconnect()
    
    # ==================== USUARIOS ====================
    
    def create_user(self, username: str, email: str = None) -> int:
        """Crear un nuevo usuario."""
        cursor = self.execute(
            "INSERT INTO users (username, email) VALUES (?, ?)",
            (username, email)
        )
        self.commit()
        logger.info(f"Usuario creado: {username}")
        return cursor.lastrowid
    
    def get_user_by_id(self, user_id: int) -> Optional[Dict]:
        """Obtener un usuario por ID."""
        cursor = self.execute("SELECT * FROM users WHERE id = ?", (user_id,))
        row = cursor.fetchone()
        return dict(row) if row else None
    
    def get_user_by_username(self, username: str) -> Optional[Dict]:
        """Obtener un usuario por nombre de usuario."""
        cursor = self.execute("SELECT * FROM users WHERE username = ?", (username,))
        row = cursor.fetchone()
        return dict(row) if row else None
    
    def get_all_users(self) -> List[Dict]:
        """Obtener todos los usuarios activos."""
        cursor = self.execute("SELECT * FROM users WHERE is_active = 1")
        return [dict(row) for row in cursor.fetchall()]
    
    # ==================== CATEGORÍAS ====================
    
    def create_category(self, user_id: int, name: str, color: str = None, icon: str = None) -> int:
        """Crear una nueva categoría."""
        cursor = self.execute(
            "INSERT INTO categories (user_id, name, color, icon) VALUES (?, ?, ?, ?)",
            (user_id, name, color, icon)
        )
        self.commit()
        logger.info(f"Categoría creada para usuario {user_id}: {name}")
        return cursor.lastrowid
    
    def get_categories_by_user(self, user_id: int) -> List[Dict]:
        """Obtener todas las categorías de un usuario."""
        cursor = self.execute("SELECT * FROM categories WHERE user_id = ? ORDER BY name", (user_id,))
        return [dict(row) for row in cursor.fetchall()]
    
    def update_category(self, category_id: int, name: str = None, color: str = None, icon: str = None):
        """Actualizar una categoría."""
        updates = []
        params = []
        if name:
            updates.append("name = ?")
            params.append(name)
        if color:
            updates.append("color = ?")
            params.append(color)
        if icon:
            updates.append("icon = ?")
            params.append(icon)
        
        if updates:
            params.append(category_id)
            query = f"UPDATE categories SET {', '.join(updates)} WHERE id = ?"
            self.execute(query, tuple(params))
            self.commit()
            logger.info(f"Categoría actualizada: {category_id}")
    
    def delete_category(self, category_id: int):
        """Eliminar una categoría."""
        self.execute("DELETE FROM categories WHERE id = ?", (category_id,))
        self.commit()
        logger.info(f"Categoría eliminada: {category_id}")
    
    # ==================== GASTOS ====================
    
    def create_expense(self, user_id: int, amount: float, description: str, 
                      date: str, quincenal_cycle: int, category_ids: List[int], 
                      status: str = "pending") -> int:
        """Crear un nuevo gasto con múltiples categorías."""
        cursor = self.execute(
            "INSERT INTO expenses (user_id, amount, description, date, quincenal_cycle, status) VALUES (?, ?, ?, ?, ?, ?)",
            (user_id, amount, description, date, quincenal_cycle, status)
        )
        self.commit()
        expense_id = cursor.lastrowid
        
        # Agregar categorías
        for cat_id in category_ids:
            self.execute(
                "INSERT INTO expense_categories (expense_id, category_id) VALUES (?, ?)",
                (expense_id, cat_id)
            )
        self.commit()
        logger.info(f"Gasto creado: {expense_id}")
        return expense_id
    
    def get_expenses_by_user_and_quincenal(self, user_id: int, year: int, month: int, 
                                           quincenal_cycle: int = None) -> List[Dict]:
        """Obtener gastos de un usuario en una quincena específica."""
        if quincenal_cycle:
            cursor = self.execute(
                """SELECT e.*, GROUP_CONCAT(ec.category_id, ',') as category_ids
                   FROM expenses e
                   LEFT JOIN expense_categories ec ON e.id = ec.expense_id
                   WHERE e.user_id = ? AND strftime('%Y', e.date) = ? 
                   AND strftime('%m', e.date) = ? AND e.quincenal_cycle = ?
                   GROUP BY e.id ORDER BY e.date DESC""",
                (user_id, str(year).zfill(4), str(month).zfill(2), quincenal_cycle)
            )
        else:
            cursor = self.execute(
                """SELECT e.*, GROUP_CONCAT(ec.category_id, ',') as category_ids
                   FROM expenses e
                   LEFT JOIN expense_categories ec ON e.id = ec.expense_id
                   WHERE e.user_id = ? AND strftime('%Y', e.date) = ? 
                   AND strftime('%m', e.date) = ?
                   GROUP BY e.id ORDER BY e.date DESC""",
                (user_id, str(year).zfill(4), str(month).zfill(2))
            )
        return [dict(row) for row in cursor.fetchall()]
    
    def update_expense(self, expense_id: int, amount: float = None, description: str = None,
                      date: str = None, status: str = None, category_ids: List[int] = None):
        """Actualizar un gasto."""
        updates = []
        params = []
        
        if amount is not None:
            updates.append("amount = ?")
            params.append(amount)
        if description:
            updates.append("description = ?")
            params.append(description)
        if date:
            updates.append("date = ?")
            params.append(date)
        if status:
            updates.append("status = ?")
            params.append(status)
        
        if updates:
            updates.append("updated_at = CURRENT_TIMESTAMP")
            params.append(expense_id)
            query = f"UPDATE expenses SET {', '.join(updates)} WHERE id = ?"
            self.execute(query, tuple(params))
            self.commit()
        
        # Actualizar categorías si se proporciona
        if category_ids is not None:
            self.execute("DELETE FROM expense_categories WHERE expense_id = ?", (expense_id,))
            for cat_id in category_ids:
                self.execute(
                    "INSERT INTO expense_categories (expense_id, category_id) VALUES (?, ?)",
                    (expense_id, cat_id)
                )
            self.commit()
        
        logger.info(f"Gasto actualizado: {expense_id}")
    
    def delete_expense(self, expense_id: int):
        """Eliminar un gasto."""
        self.execute("DELETE FROM expenses WHERE id = ?", (expense_id,))
        self.commit()
        logger.info(f"Gasto eliminado: {expense_id}")
    
    def get_expense_by_id(self, expense_id: int) -> Optional[Dict]:
        """Obtener un gasto por ID."""
        cursor = self.execute(
            """SELECT e.*, GROUP_CONCAT(ec.category_id, ',') as category_ids
               FROM expenses e
               LEFT JOIN expense_categories ec ON e.id = ec.expense_id
               WHERE e.id = ?
               GROUP BY e.id""",
            (expense_id,)
        )
        row = cursor.fetchone()
        return dict(row) if row else None
    
    # ==================== PRESUPUESTOS ====================
    
    def set_budget(self, user_id: int, category_id: int, amount: float, 
                  quincenal_cycle: int, year: int, month: int):
        """Establecer presupuesto para una categoría en una quincena."""
        self.execute(
            """INSERT OR REPLACE INTO budgets 
               (user_id, category_id, amount, quincenal_cycle, year, month)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (user_id, category_id, amount, quincenal_cycle, year, month)
        )
        self.commit()
        logger.info(f"Presupuesto establecido para usuario {user_id}, categoría {category_id}")
    
    def get_budget(self, user_id: int, category_id: int, quincenal_cycle: int, 
                  year: int, month: int) -> Optional[float]:
        """Obtener presupuesto para una categoría en una quincena."""
        cursor = self.execute(
            """SELECT amount FROM budgets 
               WHERE user_id = ? AND category_id = ? AND quincenal_cycle = ? 
               AND year = ? AND month = ?""",
            (user_id, category_id, quincenal_cycle, year, month)
        )
        row = cursor.fetchone()
        return row[0] if row else None
    
    # ==================== PAGOS FIJOS ====================
    
    def create_fixed_payment(self, user_id: int, name: str, amount: float, 
                            due_day: int, category_id: int = None, frequency: str = "monthly") -> int:
        """Crear un pago fijo/subscripción."""
        cursor = self.execute(
            """INSERT INTO fixed_payments (user_id, name, amount, category_id, due_day, frequency)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (user_id, name, amount, category_id, due_day, frequency)
        )
        self.commit()
        logger.info(f"Pago fijo creado para usuario {user_id}: {name}")
        return cursor.lastrowid
    
    def get_fixed_payments_by_user(self, user_id: int) -> List[Dict]:
        """Obtener todos los pagos fijos de un usuario."""
        cursor = self.execute(
            "SELECT * FROM fixed_payments WHERE user_id = ? AND is_active = 1 ORDER BY due_day",
            (user_id,)
        )
        return [dict(row) for row in cursor.fetchall()]
    
    def update_fixed_payment(self, payment_id: int, name: str = None, amount: float = None,
                            due_day: int = None, category_id: int = None):
        """Actualizar un pago fijo."""
        updates = []
        params = []
        
        if name:
            updates.append("name = ?")
            params.append(name)
        if amount is not None:
            updates.append("amount = ?")
            params.append(amount)
        if due_day:
            updates.append("due_day = ?")
            params.append(due_day)
        if category_id:
            updates.append("category_id = ?")
            params.append(category_id)
        
        if updates:
            updates.append("updated_at = CURRENT_TIMESTAMP")
            params.append(payment_id)
            query = f"UPDATE fixed_payments SET {', '.join(updates)} WHERE id = ?"
            self.execute(query, tuple(params))
            self.commit()
            logger.info(f"Pago fijo actualizado: {payment_id}")
    
    def delete_fixed_payment(self, payment_id: int):
        """Eliminar un pago fijo (marcarlo como inactivo)."""
        self.execute("UPDATE fixed_payments SET is_active = 0 WHERE id = ?", (payment_id,))
        self.commit()
        logger.info(f"Pago fijo eliminado: {payment_id}")
    
    # ==================== INGRESOS EXTRAS ====================
    
    def create_extra_income(self, user_id: int, amount: float, description: str, 
                           date: str, income_type: str = "bonus") -> int:
        """Crear un ingreso extra."""
        cursor = self.execute(
            """INSERT INTO extra_income (user_id, amount, description, date, income_type)
               VALUES (?, ?, ?, ?, ?)""",
            (user_id, amount, description, date, income_type)
        )
        self.commit()
        logger.info(f"Ingreso extra creado para usuario {user_id}")
        return cursor.lastrowid
    
    def get_extra_income_by_user_and_quincenal(self, user_id: int, year: int, month: int) -> List[Dict]:
        """Obtener ingresos extras de un usuario en un mes."""
        cursor = self.execute(
            """SELECT * FROM extra_income 
               WHERE user_id = ? AND strftime('%Y', date) = ? AND strftime('%m', date) = ?
               ORDER BY date DESC""",
            (user_id, str(year).zfill(4), str(month).zfill(2))
        )
        return [dict(row) for row in cursor.fetchall()]
    
    # ==================== AHORRO ====================
    
    def record_savings(self, user_id: int, amount: float, year: int, month: int, quincenal_cycle: int):
        """Registrar ahorro de una quincena."""
        self.execute(
            """INSERT OR REPLACE INTO savings 
               (user_id, last_quincenal_savings, total_saved, year, month, quincenal_cycle)
               VALUES (?, ?, 
                   COALESCE((SELECT total_saved FROM savings 
                    WHERE user_id = ? ORDER BY created_at DESC LIMIT 1), 0) + ?,
                   ?, ?, ?)""",
            (user_id, amount, user_id, amount, year, month, quincenal_cycle)
        )
        self.commit()
        logger.info(f"Ahorro registrado para usuario {user_id}: {amount}")

    def add_extra_savings(self, user_id: int, amount: float, year: int, month: int,
                          quincenal_cycle: int):
        """Aporte extra al ahorro total sin afectar el ahorro del período."""
        cursor = self.execute(
            """SELECT id FROM savings
               WHERE user_id = ?
               ORDER BY created_at DESC LIMIT 1""",
            (user_id,)
        )
        row = cursor.fetchone()

        if row and row[0] is not None:
            self.execute(
                "UPDATE savings SET total_saved = total_saved + ? WHERE id = ?",
                (amount, int(row[0]))
            )
        else:
            self.execute(
                """INSERT INTO savings
                   (user_id, last_quincenal_savings, total_saved, year, month, quincenal_cycle)
                   VALUES (?, 0, ?, ?, ?, ?)""",
                (user_id, amount, year, month, quincenal_cycle)
            )

        self.commit()
        logger.info(f"Aporte extra al ahorro total para usuario {user_id}: {amount}")
    
    def get_total_savings(self, user_id: int) -> float:
        """Obtener ahorro total acumulado."""
        cursor = self.execute(
            """SELECT total_saved FROM savings WHERE user_id = ? 
               ORDER BY created_at DESC LIMIT 1""",
            (user_id,)
        )
        row = cursor.fetchone()
        return row[0] if row and row[0] is not None else 0

    def withdraw_savings(self, user_id: int, amount: float) -> bool:
        """Retirar del ahorro total. Retorna True si exitoso."""
        current = self.get_total_savings(user_id)
        if amount > current:
            return False
        self.execute(
            """UPDATE savings SET total_saved = total_saved - ?
               WHERE user_id = ? AND id = (
                   SELECT id FROM savings WHERE user_id = ?
                   ORDER BY created_at DESC LIMIT 1
               )""",
            (amount, user_id, user_id)
        )
        self.commit()
        logger.info(f"Retiro de ahorro para usuario {user_id}: {amount}")
        return True

    def get_savings_by_quincenal(self, user_id: int, year: int, month: int, 
                                 quincenal_cycle: int) -> Optional[Dict]:
        """Obtener ahorro de una quincena específica."""
        cursor = self.execute(
            """SELECT * FROM savings 
               WHERE user_id = ? AND year = ? AND month = ? AND quincenal_cycle = ?""",
            (user_id, year, month, quincenal_cycle)
        )
        row = cursor.fetchone()
        return dict(row) if row else None

    # ==================== PRÉSTAMOS ====================

    def create_loan(self, user_id: int, person: str, amount: float,
                    description: str, date: str, deduction_type: str = "ninguno") -> int:
        """Crear un préstamo."""
        cursor = self.execute(
            """INSERT INTO loans (user_id, person, amount, description, date, deduction_type)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (user_id, person, amount, description, date, deduction_type)
        )
        self.commit()
        logger.info(f"Préstamo creado para usuario {user_id}: {person} - {amount}")
        return cursor.lastrowid

    def get_loans_by_user(self, user_id: int, include_paid: bool = False) -> List[Dict]:
        """Obtener préstamos de un usuario."""
        if include_paid:
            cursor = self.execute(
                "SELECT * FROM loans WHERE user_id = ? ORDER BY is_paid ASC, date DESC",
                (user_id,)
            )
        else:
            cursor = self.execute(
                "SELECT * FROM loans WHERE user_id = ? AND is_paid = 0 ORDER BY date DESC",
                (user_id,)
            )
        return [dict(row) for row in cursor.fetchall()]

    def mark_loan_paid(self, loan_id: int) -> None:
        """Marcar un préstamo como pagado."""
        self.execute(
            "UPDATE loans SET is_paid = 1, paid_date = DATE('now') WHERE id = ?",
            (loan_id,)
        )
        self.commit()
        logger.info(f"Préstamo {loan_id} marcado como pagado")

    def delete_loan(self, loan_id: int) -> None:
        """Eliminar un préstamo."""
        self.execute("DELETE FROM loans WHERE id = ?", (loan_id,))
        self.commit()
        logger.info(f"Préstamo {loan_id} eliminado")

    def get_total_unpaid_loans(self, user_id: int) -> float:
        """Total de préstamos pendientes."""
        cursor = self.execute(
            "SELECT COALESCE(SUM(amount), 0) FROM loans WHERE user_id = ? AND is_paid = 0",
            (user_id,)
        )
        return float(cursor.fetchone()[0])

    def get_total_loans_affecting_budget(self, user_id: int) -> float:
        """Total de préstamos pendientes que afectan el presupuesto."""
        cursor = self.execute(
            """SELECT COALESCE(SUM(amount), 0) FROM loans
               WHERE user_id = ? AND is_paid = 0
               AND (deduction_type IS NULL OR deduction_type = 'ninguno')""",
            (user_id,)
        )
        return float(cursor.fetchone()[0])

    # ==================== SALARIO ====================

    def set_salary(self, user_id: int, amount: float) -> None:
        """Establecer o actualizar el salario del usuario."""
        self.execute(
            """INSERT INTO user_salary (user_id, amount, updated_at)
               VALUES (?, ?, CURRENT_TIMESTAMP)
               ON CONFLICT(user_id) DO UPDATE SET amount = excluded.amount,
               updated_at = CURRENT_TIMESTAMP""",
            (user_id, amount)
        )
        self.commit()
        logger.info(f"Salario actualizado para usuario {user_id}: {amount}")

    def get_salary(self, user_id: int) -> float:
        """Obtener salario del usuario."""
        cursor = self.execute(
            "SELECT amount FROM user_salary WHERE user_id = ?", (user_id,)
        )
        row = cursor.fetchone()
        return float(row[0]) if row else 0.0

    def set_salary_override(self, user_id: int, year: int, month: int,
                            cycle: int, amount: float) -> None:
        """Guardar salario específico para una quincena concreta."""
        self.execute(
            """INSERT INTO salary_overrides (user_id, year, month, cycle, amount, updated_at)
               VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
               ON CONFLICT(user_id, year, month, cycle)
               DO UPDATE SET amount = excluded.amount, updated_at = CURRENT_TIMESTAMP""",
            (user_id, year, month, cycle, amount)
        )
        self.commit()
        logger.info(
            f"Salario override actualizado u{user_id} y{year} m{month} c{cycle}: {amount}"
        )

    def get_salary_override(self, user_id: int, year: int, month: int,
                            cycle: int) -> Optional[float]:
        """Obtener salario específico de una quincena; None si no existe."""
        cursor = self.execute(
            """SELECT amount FROM salary_overrides
               WHERE user_id = ? AND year = ? AND month = ? AND cycle = ?""",
            (user_id, year, month, cycle)
        )
        row = cursor.fetchone()
        return float(row[0]) if row else None

    def delete_salary_override(self, user_id: int, year: int, month: int,
                               cycle: int) -> None:
        """Eliminar salario específico de una quincena para volver al salario base."""
        self.execute(
            """DELETE FROM salary_overrides
               WHERE user_id = ? AND year = ? AND month = ? AND cycle = ?""",
            (user_id, year, month, cycle)
        )
        self.commit()
        logger.info(f"Salario override eliminado u{user_id} y{year} m{month} c{cycle}")

    def set_period_mode(self, user_id: int, mode: str) -> None:
        """Guardar modo de período del usuario: quincenal o mensual."""
        mode = (mode or "quincenal").strip().lower()
        if mode not in ("quincenal", "mensual"):
            mode = "quincenal"
        self.execute(
            """INSERT INTO user_period_mode (user_id, mode, updated_at)
               VALUES (?, ?, CURRENT_TIMESTAMP)
               ON CONFLICT(user_id) DO UPDATE SET mode = excluded.mode,
               updated_at = CURRENT_TIMESTAMP""",
            (user_id, mode)
        )
        self.commit()
        logger.info(f"Modo de período actualizado para usuario {user_id}: {mode}")

    def get_period_mode(self, user_id: int) -> str:
        """Obtener modo de período del usuario (quincenal por defecto)."""
        cursor = self.execute(
            "SELECT mode FROM user_period_mode WHERE user_id = ?",
            (user_id,)
        )
        row = cursor.fetchone()
        mode = str(row[0]).strip().lower() if row else "quincenal"
        return mode if mode in ("quincenal", "mensual") else "quincenal"

    def set_user_setting(self, user_id: int, setting_key: str, setting_value: str) -> None:
        """Guardar configuración personalizada del usuario."""
        self.execute(
            """INSERT INTO user_settings (user_id, setting_key, setting_value, updated_at)
               VALUES (?, ?, ?, CURRENT_TIMESTAMP)
               ON CONFLICT(user_id, setting_key)
               DO UPDATE SET setting_value = excluded.setting_value,
               updated_at = CURRENT_TIMESTAMP""",
            (user_id, setting_key, setting_value)
        )
        self.commit()

    def get_user_setting(self, user_id: int, setting_key: str,
                         default_value: str = "") -> str:
        """Leer configuración personalizada del usuario."""
        cursor = self.execute(
            """SELECT setting_value FROM user_settings
               WHERE user_id = ? AND setting_key = ?""",
            (user_id, setting_key)
        )
        row = cursor.fetchone()
        if not row:
            return default_value
        return str(row[0])

    # ==================== INGRESOS EXTRAS (mejorado) ====================

    def get_extra_income_by_quincenal(self, user_id: int, year: int, month: int,
                                      quincenal_cycle: int) -> List[Dict]:
        """Obtener ingresos extras filtrados por quincena."""
        if quincenal_cycle == 1:
            start_d = f"{year}-{month:02d}-01"
            end_d = f"{year}-{month:02d}-15"
        else:
            _, last = monthrange(year, month)
            start_d = f"{year}-{month:02d}-16"
            end_d = f"{year}-{month:02d}-{last}"
        cursor = self.execute(
            """SELECT * FROM extra_income
               WHERE user_id = ? AND date >= ? AND date <= ?
               ORDER BY date DESC""",
            (user_id, start_d, end_d)
        )
        return [dict(row) for row in cursor.fetchall()]

    def get_total_extra_income_quincenal(self, user_id: int, year: int, month: int,
                                         quincenal_cycle: int) -> float:
        """Total de ingresos extras en una quincena."""
        if quincenal_cycle == 1:
            start_d = f"{year}-{month:02d}-01"
            end_d = f"{year}-{month:02d}-15"
        else:
            _, last = monthrange(year, month)
            start_d = f"{year}-{month:02d}-16"
            end_d = f"{year}-{month:02d}-{last}"
        cursor = self.execute(
            "SELECT COALESCE(SUM(amount), 0) FROM extra_income WHERE user_id = ? AND date >= ? AND date <= ?",
            (user_id, start_d, end_d)
        )
        return float(cursor.fetchone()[0])

    def delete_extra_income(self, income_id: int) -> None:
        """Eliminar un ingreso extra."""
        self.execute("DELETE FROM extra_income WHERE id = ?", (income_id,))
        self.commit()
        logger.info(f"Ingreso extra {income_id} eliminado")

    # ==================== METAS DE AHORRO ====================

    def create_savings_goal(self, user_id: int, name: str, target_amount: float) -> int:
        """Crear una meta de ahorro."""
        cursor = self.execute(
            "INSERT INTO savings_goals (user_id, name, target_amount) VALUES (?, ?, ?)",
            (user_id, name, target_amount)
        )
        self.commit()
        logger.info(f"Meta de ahorro creada para usuario {user_id}: {name}")
        return cursor.lastrowid

    def get_savings_goals(self, user_id: int) -> List[Dict]:
        """Obtener metas de ahorro del usuario."""
        cursor = self.execute(
            "SELECT * FROM savings_goals WHERE user_id = ? ORDER BY created_at",
            (user_id,)
        )
        return [dict(row) for row in cursor.fetchall()]

    def delete_savings_goal(self, goal_id: int) -> None:
        """Eliminar una meta de ahorro."""
        self.execute("DELETE FROM savings_goals WHERE id = ?", (goal_id,))
        self.commit()
        logger.info(f"Meta de ahorro {goal_id} eliminada")

    def update_savings_goal(self, goal_id: int, name: str = None, target_amount: float = None):
        """Actualizar una meta de ahorro."""
        updates = []
        params = []
        if name:
            updates.append("name = ?")
            params.append(name)
        if target_amount is not None:
            updates.append("target_amount = ?")
            params.append(target_amount)
        if updates:
            params.append(goal_id)
            query = f"UPDATE savings_goals SET {', '.join(updates)} WHERE id = ?"
            self.execute(query, tuple(params))
            self.commit()
            logger.info(f"Meta de ahorro actualizada: {goal_id}")

    # ==================== PRÉSTAMOS (update) ====================

    def update_loan(self, loan_id: int, person: str = None, amount: float = None,
                    description: str = None, deduction_type: str = None):
        """Actualizar un préstamo."""
        updates = []
        params = []
        if person:
            updates.append("person = ?")
            params.append(person)
        if amount is not None:
            updates.append("amount = ?")
            params.append(amount)
        if description is not None:
            updates.append("description = ?")
            params.append(description)
        if deduction_type is not None:
            updates.append("deduction_type = ?")
            params.append(deduction_type)
        if updates:
            params.append(loan_id)
            query = f"UPDATE loans SET {', '.join(updates)} WHERE id = ?"
            self.execute(query, tuple(params))
            self.commit()
            logger.info(f"Préstamo actualizado: {loan_id}")

    # ==================== INGRESOS EXTRAS (update) ====================

    def update_extra_income(self, income_id: int, amount: float = None,
                            description: str = None, date: str = None):
        """Actualizar un ingreso extra."""
        updates = []
        params = []
        if amount is not None:
            updates.append("amount = ?")
            params.append(amount)
        if description:
            updates.append("description = ?")
            params.append(description)
        if date:
            updates.append("date = ?")
            params.append(date)
        if updates:
            params.append(income_id)
            query = f"UPDATE extra_income SET {', '.join(updates)} WHERE id = ?"
            self.execute(query, tuple(params))
            self.commit()
            logger.info(f"Ingreso extra actualizado: {income_id}")

    # ==================== QUINCENAS PERSONALIZADAS ====================

    def create_custom_quincena_table(self):
        """Crear tabla de quincenas personalizadas si no existe."""
        self.connect()
        cursor = self.connection.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS custom_quincena (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                year INTEGER NOT NULL,
                month INTEGER NOT NULL,
                cycle INTEGER NOT NULL,
                start_date TEXT NOT NULL,
                end_date TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id),
                UNIQUE(user_id, year, month, cycle)
            )
        ''')
        self.connection.commit()

    def set_custom_quincena(self, user_id: int, year: int, month: int,
                            cycle: int, start_date: str, end_date: str):
        """Establecer o actualizar fechas personalizadas de una quincena."""
        self.execute(
            """INSERT INTO custom_quincena (user_id, year, month, cycle, start_date, end_date)
               VALUES (?, ?, ?, ?, ?, ?)
               ON CONFLICT(user_id, year, month, cycle) DO UPDATE SET
               start_date = excluded.start_date, end_date = excluded.end_date""",
            (user_id, year, month, cycle, start_date, end_date)
        )
        self.commit()
        logger.info(f"Quincena personalizada: {year}-{month:02d} Q{cycle} = {start_date} → {end_date}")

    def get_custom_quincena(self, user_id: int, year: int, month: int,
                            cycle: int) -> Optional[Dict]:
        """Obtener quincena personalizada."""
        cursor = self.execute(
            """SELECT * FROM custom_quincena
               WHERE user_id = ? AND year = ? AND month = ? AND cycle = ?""",
            (user_id, year, month, cycle)
        )
        row = cursor.fetchone()
        return dict(row) if row else None

    def delete_custom_quincena(self, cq_id: int):
        """Eliminar quincena personalizada."""
        self.execute("DELETE FROM custom_quincena WHERE id = ?", (cq_id,))
        self.commit()
        logger.info(f"Quincena personalizada {cq_id} eliminada")

    def get_custom_quincena_range(self, user_id: int, year: int, month: int,
                                   cycle: int) -> Optional[Tuple[str, str]]:
        """Retorna (start_date, end_date) si hay quincena personalizada, None si no."""
        cq = self.get_custom_quincena(user_id, year, month, cycle)
        if cq:
            return cq["start_date"], cq["end_date"]
        return None

    def get_expenses_by_custom_range(self, user_id: int, start_date: str,
                                      end_date: str) -> List[Dict]:
        """Obtener gastos en un rango de fechas personalizado."""
        cursor = self.execute(
            """SELECT e.*, GROUP_CONCAT(ec.category_id, ',') as category_ids
               FROM expenses e
               LEFT JOIN expense_categories ec ON e.id = ec.expense_id
               WHERE e.user_id = ? AND e.date >= ? AND e.date <= ?
               GROUP BY e.id ORDER BY e.date DESC""",
            (user_id, start_date, end_date)
        )
        return [dict(row) for row in cursor.fetchall()]

    def get_extra_income_by_custom_range(self, user_id: int, start_date: str,
                                          end_date: str) -> List[Dict]:
        """Obtener ingresos extras en un rango de fechas personalizado."""
        cursor = self.execute(
            """SELECT * FROM extra_income
               WHERE user_id = ? AND date >= ? AND date <= ?
               ORDER BY date DESC""",
            (user_id, start_date, end_date)
        )
        return [dict(row) for row in cursor.fetchall()]

    def get_total_extra_income_by_custom_range(self, user_id: int, start_date: str,
                                                end_date: str) -> float:
        """Total de ingresos extras en un rango personalizado."""
        cursor = self.execute(
            "SELECT COALESCE(SUM(amount), 0) FROM extra_income WHERE user_id = ? AND date >= ? AND date <= ?",
            (user_id, start_date, end_date)
        )
        return float(cursor.fetchone()[0])
