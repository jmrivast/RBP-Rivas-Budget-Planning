"""
Modelo de datos para gastos.
"""
from dataclasses import dataclass
from datetime import datetime
from typing import List


@dataclass
class Expense:
    """Clase que representa un gasto."""
    id: int
    user_id: int
    amount: float
    description: str
    date: str
    quincenal_cycle: int
    status: str  # 'pending' o 'completed'
    category_ids: List[int]
    created_at: str = None
    updated_at: str = None
    
    def __str__(self):
        return f"{self.description} - ${self.amount:.2f} ({', '.join(map(str, self.category_ids))})"
    
    @property
    def is_pending(self) -> bool:
        """Verificar si el gasto está pendiente."""
        return self.status == "pending"
    
    @property
    def is_completed(self) -> bool:
        """Verificar si el gasto está completado."""
        return self.status == "completed"


@dataclass
class Category:
    """Clase que representa una categoría."""
    id: int
    user_id: int
    name: str
    color: str = None
    icon: str = None
    created_at: str = None
    
    def __str__(self):
        return self.name


@dataclass
class Budget:
    """Clase que representa un presupuesto."""
    id: int
    user_id: int
    category_id: int
    amount: float
    quincenal_cycle: int
    year: int
    month: int
    created_at: str = None
    
    def __str__(self):
        return f"{self.amount:.2f} RD$ - Q{self.quincenal_cycle} {self.month}/{self.year}"


@dataclass
class FixedPayment:
    """Clase que representa un pago fijo/subscripción."""
    id: int
    user_id: int
    name: str
    amount: float
    due_day: int
    category_id: int = None
    frequency: str = "monthly"
    is_active: bool = True
    created_at: str = None
    updated_at: str = None
    
    def __str__(self):
        return f"{self.name} - ${self.amount:.2f} (día {self.due_day})"


@dataclass
class ExtraIncome:
    """Clase que representa un ingreso extra."""
    id: int
    user_id: int
    amount: float
    description: str
    date: str
    income_type: str = "bonus"
    created_at: str = None
    
    def __str__(self):
        return f"{self.description} - ${self.amount:.2f}"


@dataclass
class SavingsRecord:
    """Clase que representa un registro de ahorro."""
    id: int
    user_id: int
    total_saved: float
    last_quincenal_savings: float
    year: int
    month: int
    quincenal_cycle: int
    created_at: str = None
    updated_at: str = None
    
    def __str__(self):
        return f"${self.total_saved:.2f} (Quincena {self.quincenal_cycle})"
