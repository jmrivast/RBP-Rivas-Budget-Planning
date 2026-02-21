"""
Script de inicialización con datos de prueba.
Ejecuta este script una sola vez para poblar la base de datos con datos de ejemplo.
"""
from pathlib import Path
import sys

# Agregar el directorio del proyecto al path
PROJECT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(PROJECT_DIR))

from src.config import DB_PATH, DEFAULT_CATEGORIES, DEFAULT_BUDGETS
from src.db.database import Database
from datetime import datetime, timedelta
import random

def init_sample_data():
    """Inicializar base de datos con datos de prueba."""
    db = Database(DB_PATH)
    db.connect()
    
    # Crear usuario de prueba
    print("Creando usuario de prueba...")
    existing_user = db.get_user_by_username("Jose")
    if existing_user:
        user_id = existing_user["id"]
        print(f"✓ Usuario existente reutilizado: Jose (ID: {user_id})")
    else:
        user_id = db.create_user("Jose", "jose@example.com")
        print(f"✓ Usuario creado: Jose (ID: {user_id})")
    
    # Crear categorías por defecto
    print("\nCreando categorías...")
    category_ids = {}
    existing_categories = {c["name"]: c["id"] for c in db.get_categories_by_user(user_id)}
    for cat_name in DEFAULT_CATEGORIES:
        if cat_name in existing_categories:
            cat_id = existing_categories[cat_name]
            print(f"✓ Categoría existente reutilizada: {cat_name}")
        else:
            cat_id = db.create_category(user_id, cat_name)
            print(f"✓ Categoría creada: {cat_name}")
        category_ids[cat_name] = cat_id
    
    # Crear presupuestos para esta quincena
    print("\nEstableciendo presupuestos...")
    now = datetime.now()
    for cat_name, budget_amount in DEFAULT_BUDGETS.items():
        if cat_name in category_ids:
            quincenal_cycle = 1 if now.day <= 15 else 2
            db.set_budget(
                user_id,
                category_ids[cat_name],
                budget_amount,
                quincenal_cycle,
                now.year,
                now.month
            )
            print(f"✓ Presupuesto {cat_name}: RD${budget_amount:,.2f}")
    
    # Crear gastos de ejemplo
    print("\nCreando gastos de ejemplo...")
    expenses_data = [
        {
            "amount": 250.00,
            "description": "McDonald's - Almuerzo",
            "categories": ["Comida"],
            "days_ago": 5
        },
        {
            "amount": 500.00,
            "description": "Combustible",
            "categories": ["Combustible"],
            "days_ago": 4
        },
        {
            "amount": 150.00,
            "description": "Uber - Trabajo",
            "categories": ["Uber/Taxi"],
            "days_ago": 3
        },
        {
            "amount": 65.00,
            "description": "Netflix",
            "categories": ["Subscripciones"],
            "days_ago": 2
        },
        {
            "amount": 100.00,
            "description": "Snacks en la tienda",
            "categories": ["Varios/Snacks"],
            "days_ago": 2
        },
        {
            "amount": 350.00,
            "description": "Comida en Chipotle",
            "categories": ["Comida"],
            "days_ago": 1
        },
    ]
    
    for expense in expenses_data:
        expense_date = (now - timedelta(days=expense["days_ago"])).strftime("%Y-%m-%d")
        quincenal_cycle = 1 if int(expense_date.split("-")[2]) <= 15 else 2
        
        cat_ids = [category_ids[cat] for cat in expense["categories"] if cat in category_ids]
        
        db.create_expense(
            user_id,
            expense["amount"],
            expense["description"],
            expense_date,
            quincenal_cycle,
            cat_ids,
            "completed"
        )
        print(f"✓ Gasto registrado: {expense['description']} - RD${expense['amount']:.2f}")
    
    # Crear pagos fijos de ejemplo
    print("\nCreando pagos fijos...")
    fixed_payments = [
        {"name": "Netflix", "amount": 270.00, "due_day": 15, "category": "Subscripciones"},
        {"name": "Amazon Prime", "amount": 470.50, "due_day": 10, "category": "Subscripciones"},
        {"name": "Gym", "amount": 500.00, "due_day": 1, "category": "Otros"},
    ]
    
    for payment in fixed_payments:
        cat_id = category_ids.get(payment["category"], category_ids.get("Otros"))
        db.create_fixed_payment(
            user_id,
            payment["name"],
            payment["amount"],
            payment["due_day"],
            cat_id
        )
        print(f"✓ Pago fijo creado: {payment['name']} - RD${payment['amount']:.2f}")
    
    # Registrar ahorro
    print("\nRegistrando ahorros...")
    quincenal_cycle = 1 if now.day <= 15 else 2
    db.record_savings(user_id, 7500.00, now.year, now.month, quincenal_cycle)
    print(f"✓ Ahorro registrado: RD$7,500.00")
    
    db.disconnect()
    
    print("\n" + "="*50)
    print("✓ Base de datos inicializada exitosamente")
    print("="*50)
    print("\nCuenta de prueba:")
    print("  Usuario: Jose")
    print("  Contraseña: N/A (es acceso por nombre de usuario)")
    print("\nAhora ejecuta: python main.py")

if __name__ == "__main__":
    init_sample_data()
