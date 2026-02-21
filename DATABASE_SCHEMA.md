# Database Schema Documentation

## Diagrama Entidad-Relación (ER)

```
┌─────────────────────────────────────────────────────────────┐
│                     USUARIOS (users)                        │
├──────────────────────────────────────────────────────────────┤
│ id (PK)                                                      │
│ username (UNIQUE)                                            │
│ email                                                        │
│ created_at                                                   │
│ is_active                                                    │
└──────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┼─────────┐
                    │         │         │
                    ↓         ↓         ↓
    ┌──────────────────┐  ┌─────────────────┐  ┌──────────────────┐
    │  CATEGORÍAS      │  │   GASTOS        │  │  PRESUPUESTOS    │
    │  (categories)    │  │  (expenses)     │  │  (budgets)       │
    ├──────────────────┤  ├─────────────────┤  ├──────────────────┤
    │ id (PK)          │  │ id (PK)         │  │ id (PK)          │
    │ user_id (FK)     │  │ user_id (FK)    │  │ user_id (FK)     │
    │ name             │  │ amount          │  │ category_id (FK) │
    │ color            │  │ description     │  │ amount           │
    │ icon             │  │ date            │  │ quincenal_cycle  │
    │ created_at       │  │ quincenal_cycle │  │ year             │
    └──────────────────┘  │ status          │  │ month            │
            ↑              │ created_at      │  │ created_at       │
            │              │ updated_at      │  └──────────────────┘
            │              └─────────────────┘
            │                       │
            │                       ↓
            │         ┌──────────────────────────┐
            │         │ GASTOS-CATEGORÍAS        │
            │         │ (expense_categories)     │
            │         ├──────────────────────────┤
            │         │ id (PK)                  │
            │         │ expense_id (FK)          │
            │         │ category_id (FK) ─────────→┤
            │         │ created_at               │
            │         └──────────────────────────┘
            │
            └────────────────────────┬────────────────────────┐
                                    │                        │
                                    ↓                        ↓
                    ┌──────────────────────┐    ┌────────────────────────┐
                    │   PAGOS FIJOS        │    │  INGRESOS EXTRAS       │
                    │ (fixed_payments)     │    │  (extra_income)        │
                    ├──────────────────────┤    ├────────────────────────┤
                    │ id (PK)              │    │ id (PK)                │
                    │ user_id (FK)         │    │ user_id (FK)           │
                    │ name                 │    │ amount                 │
                    │ amount               │    │ description            │
                    │ category_id (FK)     │    │ date                   │
                    │ due_day              │    │ income_type            │
                    │ frequency            │    │ created_at             │
                    │ is_active            │    └────────────────────────┘
                    │ created_at           │
                    │ updated_at           │
                    └──────────────────────┘
                            │
                            ↓
                    ┌──────────────────────┐
                    │ REGISTROS PAGOS FIJOS│
                    │(fixed_payment_records)
                    ├──────────────────────┤
                    │ id (PK)              │
                    │ fixed_payment_id (FK)│
                    │ expense_id (FK)      │
                    │ year                 │
                    │ month                │
                    │ quincenal_cycle      │
                    │ status               │
                    │ paid_date            │
                    │ created_at           │
                    └──────────────────────┘

                    ┌──────────────────────┐
                    │   AHORROS            │
                    │    (savings)         │
                    ├──────────────────────┤
                    │ id (PK)              │
                    │ user_id (FK)         │
                    │ total_saved          │
                    │ last_quincenal_s.    │
                    │ year                 │
                    │ month                │
                    │ quincenal_cycle      │
                    │ created_at           │
                    │ updated_at           │
                    └──────────────────────┘

                    ┌──────────────────────┐
                    │   RESPALDOS          │
                    │   (backups)          │
                    ├──────────────────────┤
                    │ id (PK)              │
                    │ user_id (FK)         │
                    │ backup_file          │
                    │ backup_date          │
                    └──────────────────────┘
```

## Descripción de Tablas

### users (Usuarios)
- **id**: Identificador único del usuario
- **username**: Nombre de usuario único
- **email**: Email del usuario (opcional)
- **created_at**: Fecha de creación
- **is_active**: Si el usuario está activo

### categories (Categorías)
- **id**: Identificador único
- **user_id**: Usuario propietario de la categoría
- **name**: Nombre de la categoría (Comida, Combustible, etc.)
- **color**: Color de la categoría (hex)
- **icon**: Ícono de la categoría (opcional)
- **created_at**: Fecha de creación

### expenses (Gastos)
- **id**: Identificador único del gasto
- **user_id**: Usuario propietario del gasto
- **amount**: Monto del gasto
- **description**: Descripción del gasto
- **date**: Fecha del gasto
- **quincenal_cycle**: 1 (1-15) o 2 (16-fin de mes)
- **status**: 'pending' o 'completed' (afecta visualización)
- **created_at**: Fecha de creación
- **updated_at**: Última actualización

### expense_categories (Relación Gastos-Categorías)
Tabla de asociación para soporte de multi-categoría
- **id**: Identificador único
- **expense_id**: Referencia al gasto
- **category_id**: Referencia a la categoría
- **created_at**: Fecha de creación

### budgets (Presupuestos)
- **id**: Identificador único
- **user_id**: Usuario propietario
- **category_id**: Categoría del presupuesto
- **amount**: Monto del presupuesto (RD$)
- **quincenal_cycle**: Ciclo de quincena
- **year**: Año
- **month**: Mes
- **created_at**: Fecha de creación

### fixed_payments (Pagos Fijos)
- **id**: Identificador único
- **user_id**: Usuario propietario
- **name**: Nombre del pago (Netflix, Spotify, etc.)
- **amount**: Monto del pago
- **category_id**: Categoría relacionada (opcional)
- **due_day**: Día del mes de vencimiento
- **frequency**: 'monthly', 'biweekly', etc.
- **is_active**: Si está activo
- **created_at**: Fecha de creación
- **updated_at**: Última actualización

### fixed_payment_records (Registro de Pagos Fijos)
Para saber si un pago fijo ya fue completado
- **id**: Identificador único
- **fixed_payment_id**: Referencia al pago fijo
- **expense_id**: Referencia al gasto si se registró
- **year**: Año
- **month**: Mes
- **quincenal_cycle**: Ciclo de quincena
- **status**: 'pending' o 'completed'
- **paid_date**: Fecha en que se pagó
- **created_at**: Fecha de creación

### extra_income (Ingresos Extras)
- **id**: Identificador único
- **user_id**: Usuario propietario
- **amount**: Monto del ingreso
- **description**: Descripción (bono, venta, etc.)
- **date**: Fecha del ingreso
- **income_type**: Tipo de ingreso ('bonus', 'freelance', etc.)
- **created_at**: Fecha de creación

### savings (Ahorros)
- **id**: Identificador único
- **user_id**: Usuario propietario
- **total_saved**: Total acumulado hasta la fecha
- **last_quincenal_savings**: Ahorro de esta quincena
- **year**: Año
- **month**: Mes
- **quincenal_cycle**: Ciclo de quincena
- **created_at**: Fecha de creación
- **updated_at**: Última actualización

### backups (Respaldos)
- **id**: Identificador único
- **user_id**: Usuario propietario del respaldo
- **backup_file**: Ruta del archivo de respaldo
- **backup_date**: Fecha del respaldo

## Relaciones Principales

1. **users → categories**: 1 a muchos (un usuario tiene múltiples categorías)
2. **users → expenses**: 1 a muchos (un usuario tiene múltiples gastos)
3. **users → budgets**: 1 a muchos (un usuario tiene múltiples presupuestos)
4. **users → fixed_payments**: 1 a muchos (un usuario tiene múltiples pagos fijos)
5. **users → extra_income**: 1 a muchos (un usuario puede recibir ingresos extras)
6. **users → savings**: 1 a muchos (un usuario tiene múltiples registros de ahorros)
7. **categories ↔ expenses**: muchos a muchos (vía expense_categories)
8. **fixed_payments → categories**: muchos a 1 (un pago fijo está asociado a una categoría)

## Notas Importantes

- Los gastos con status **'pending'** no se cuentan en el total gastado, pero el monto está "reservado"
- El ciclo quincenal se detecta automáticamente basado en el día del mes:
  - Quincena 1: días 1-15
  - Quincena 2: días 16-último día del mes
- Los presupuestos se pueden establecer por categoría, quincena, mes y año
- Los ahorros se registran automáticamente cada quincena
- Todos los registros tienen timestamps para auditoría
