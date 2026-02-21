# 📁 Estructura del Proyecto

```
finanzas_app/
│
├── 📄 main.py                          # Punto de entrada de la aplicación
├── 📄 init_sample_data.py              # Script para crear datos de prueba
├── 📄 requirements.txt                 # Dependencias Python
│
├── 📋 README.md                        # Documentación principal
├── 📋 GUIA_RAPIDA.md                   # Guía de usuario (este archivo)
├── 📋 DATABASE_SCHEMA.md               # Documentación de base de datos
├── 📋 .gitignore                       # Archivos ignorados por Git
├── 📋 .env.example                     # Plantilla de configuración
│
├── 📂 src/                             # Código fuente principal
│   ├── __init__.py
│   ├── 📄 config.py                    # Configuración centralizada
│   │
│   ├── 📂 db/                          # Capa de base de datos
│   │   ├── __init__.py
│   │   └── 📄 database.py              # Clase Database con operaciones CRUD
│   │
│   ├── 📂 models/                      # Modelos de datos
│   │   ├── __init__.py
│   │   └── 📄 expense.py               # Dataclasses (Expense, Category, etc.)
│   │
│   ├── 📂 ui/                          # Interfaz de usuario
│   │   ├── __init__.py
│   │   ├── 📄 app.py                   # Ventana principal (AppFinanzas)
│   │   │
│   │   └── 📂 frames/                  # Pantallas/frames de la app
│   │       ├── __init__.py
│   │       ├── 📄 main_frame.py        # Login y selección de usuario
│   │       ├── 📄 dashboard_frame.py   # Dashboard principal (presupuestos)
│   │       ├── 📄 expenses_frame.py    # Registro de gastos
│   │       ├── 📄 fixed_payments_frame.py    # Gestión de pagos fijos
│   │       ├── 📄 savings_frame.py     # Visualización de ahorros
│   │       └── 📄 settings_frame.py    # Configuración y categorías
│   │
│   └── 📂 utils/                       # Funciones auxiliares
│       ├── __init__.py
│       ├── 📄 helpers.py               # Funciones de utilidad (formato, cálculos)
│       ├── 📄 backup.py                # Gestión de respaldos
│       └── 📄 notifications.py         # Notificaciones por email
│
├── 📂 data/                            # Datos de la aplicación
│   └── finanzas.db                     # Base de datos SQLite (se crea automáticamente)
│
├── 📂 backups/                         # Respaldos automáticos
│   ├── finanzas_backup_20260211_143522.db
│   ├── finanzas_backup_20260210_120015.db
│   └── ...
│
└── 📂 .venv/                           # Entorno virtual Python (no versionar)
    ├── Scripts/
    │   ├── python.exe
    │   ├── pip.exe
    │   └── ...
    └── Lib/
        └── site-packages/              # Dependencias instaladas
```

## 📊 Arquitectura de Capas

```
┌─────────────────────────────────────────────────────────┐
│               🖥️  INTERFAZ DE USUARIO (UI)             │
│  (CustomTkinter - Frames y widgets)                     │
│  ├── MainFrame (Login)                                 │
│  ├── DashboardFrame (Presupuestos)                     │
│  ├── ExpensesFrame (Registro de gastos)                │
│  ├── FixedPaymentsFrame (Pagos fijos)                  │
│  ├── SavingsFrame (Ahorros)                            │
│  └── SettingsFrame (Configuración)                     │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│             ⚙️  LÓGICA DE NEGOCIOS                      │
│  (Helpers, Validators, Calculators)                    │
│  ├── calculate_budget_percentage()                     │
│  ├── get_quincenal_cycle()                             │
│  ├── format_currency()                                 │
│  └── ...                                               │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│           🗄️  ACCESO A DATOS (DATABASE)                │
│  (SQLite - CRUD Operations)                            │
│  ├── create_expense()                                  │
│  ├── get_expenses_by_user()                            │
│  ├── update_budget()                                   │
│  ├── get_fixed_payments()                              │
│  └── ...                                               │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│            💾  ALMACENAMIENTO (DATABASE)                │
│  SQLite: data/finanzas.db                              │
│  ├── users                                             │
│  ├── categories                                        │
│  ├── expenses                                          │
│  ├── budgets                                           │
│  ├── fixed_payments                                    │
│  ├── savings                                           │
│  └── ...                                               │
└─────────────────────────────────────────────────────────┘
```

## 🔄 Flujo de Datos

### Registrar un Gasto

```
Usuario ingresa datos en ExpensesFrame
         │
         ▼
    Validación de datos (en ExpensesFrame)
         │
         ▼
    Llamada a database.create_expense()
         │
         ▼
    INSERT en tabla expenses
         │
         ▼
    INSERT en tabla expense_categories (multi-categoría)
         │
         ▼
    Commit a la base de datos
         │
         ▼
    Actualizar UI (refresh_data)
         │
         ▼
    Dashboard muestra nuevo gasto
```

### Ver Presupuestos (Dashboard)

```
Usuario abre DashboardFrame
         │
         ▼
    refresh_data() es llamado
         │
         ▼
    Obtener categorías del usuario
         │
         ▼
    Para cada categoría:
    - Obtener presupuesto del mes/quincena
    - Obtener gastos "completados" del mes/quincena
    - Calcular porcentaje gastado
    - Determinar color de la barra
         │
         ▼
    Renderizar tarjetas con barras de progreso
         │
         ▼
    Mostrar disponible y ahorro acumulado
```

## 🗂️ Archivos Clave

### `config.py`
Configuración centralizada de la aplicación:
- Colores (PRIMARY_COLOR, SECONDARY_COLOR, etc.)
- Categorías por defecto
- Presupuestos por defecto
- Configuración de email

### `database.py`
Todas las operaciones de base de datos:
- `create_user()`, `get_user_by_id()`, etc.
- `create_expense()`, `get_expenses_by_user()`, etc.
- `set_budget()`, `get_budget()`, etc.
- `create_fixed_payment()`, `get_fixed_payments()`, etc.

### `app.py`
Ventana principal de la aplicación:
- Inicialización de la app
- Gesión de frames
- Navegación entre pantallas
- Gestión del usuario actual

### Frames
Cada frame representa una pantalla de la aplicación y contiene:
- `setup_ui()`: Crear widgets
- `refresh_data()`: Actualizar datos
- Métodos para manejar eventos del usuario

## 🔐 Seguridad

### Multiusuario
- Cada usuario tiene sus propios datos aislados
- No hay contraseñas (login simple por nombre de usuario)
- Los datos de otros usuarios no son visibles

### Respaldos
- Respaldos automáticos cada hora
- También puedes hacer respaldos manuales
- Los respaldos se guardan en `backups/`

### Base de Datos
- SQLite usa transacciones para consistencia
- `db.commit()` confirma cambios
- Integridad referencial con Foreign Keys

## 🚀 Cómo Agregar una Nueva Característica

### Ejemplo: Agregar una nueva categoría "Educación"

1. **Actualizar `config.py`:**
   ```python
   DEFAULT_CATEGORIES = [
       "Comida",
       "Combustible",
       "Uber/Taxi",
       "Subscripciones",
       "Varios/Snacks",
       "Educación",  # Nueva
       "Otros"
   ]
   ```

2. **Si necesitas agregar tablas, modificar `database.py`:**
   - Agregar tabla en `init_db()`
   - Agregar métodos CRUD para la tabla

3. **Agregar interfaz de usuario en un frame:**
   - En `settings_frame.py` ya puedes crear/editar categorías desde la UI

4. **Actualizar `dashboard_frame.py` si es necesario:**
   - Si necesitas mostrar la nueva categoría con presupuesto especial

## 📦 Dependencias

```
customtkinter==5.2.0    # GUI moderna
pandas==2.1.4           # Manejo de datos (futuro: Excel)
openpyxl==3.11.0        # Lectura/escritura Excel
matplotlib==3.8.2       # Gráficos (futuro)
pillow==10.1.0          # Procesamiento de imágenes
python-dotenv==1.0.0    # Variables de entorno (.env)
```

## 🎯 Puntos de Extensión Futuros

1. **Gráficos**: Usar `matplotlib` en una nueva pantalla
2. **Exportación**: `pandas` + `openpyxl` para exportar a Excel
3. **API Web**: FastAPI para backend, React para frontend
4. **Móvil**: Kivy o PWA para iOS/Android
5. **Sincronización**: Google Drive API para respaldos en la nube

---

**¡La arquitectura está lista para escalar! 🚀**
