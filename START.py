#!/usr/bin/env python
"""
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║       🎉 GESTOR DE FINANZAS PERSONAL - META 45% DE AHORRO 🎉             ║
║                                                                            ║
║              Creado con Python + CustomTkinter + SQLite                   ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝

📋 INSTRUCCIONES DE INICIO RÁPIDO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1️⃣  INSTALACIÓN (Primera vez)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    Abre una terminal/PowerShell en esta carpeta y ejecuta:

    pip install -r requirements.txt

    Esto instala:
    ✓ customtkinter      (UI moderna)
    ✓ pandas             (Manipulación de datos)
    ✓ openpyxl           (Excel)
    ✓ matplotlib         (Gráficos)
    ✓ pillow             (Imágenes)
    ✓ python-dotenv      (Variables de entorno)

    ⏱️  Tiempo de instalación: ~1-2 minutos


2️⃣  CREAR DATOS DE PRUEBA (Opcional)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    En la misma terminal, ejecuta:

    python init_sample_data.py

    Esto crea:
    ✓ Usuario de prueba: "Jose"
    ✓ Gastos de ejemplo
    ✓ Pagos fijos de ejemplo
    ✓ Ahorros registrados

    ⏱️  Tiempo de ejecución: ~5 segundos


3️⃣  EJECUTAR LA APLICACIÓN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    En la terminal, ejecuta:

    python main.py

    ✓ La ventana de la aplicación se abrirá

    ⏱️  Tiempo de inicio: ~2-3 segundos


4️⃣  PRIMER USO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    En la pantalla de login:

    a) Ingresa un nombre de usuario (ej: "Jose")
    
    b) Haz clic en "Crear Nuevo Usuario" para crear uno nuevo
       O haz clic en un usuario existente para iniciar sesión
    
    c) ¡Automáticamente se crean las categorías por defecto!
    
    d) Ya estás dentro. ¡A registrar gastos!


5️⃣  PANTALLAS PRINCIPALES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    En la barra lateral izquierda encontrarás:

    📊 Dashboard
       ├─ Presupuestos por categoría
       ├─ Barras de progreso (verde/naranja/rojo)
       ├─ Disponible para gastar
       └─ Ahorro acumulado

    💰 Registrar Gasto
       ├─ Formulario de entrada
       ├─ Múltiples categorías
       ├─ Estado (pendiente/saldado)
       └─ Historial de gastos

    🔁 Pagos Fijos
       ├─ Agregar subscripciones
       ├─ Recordatorios de vencimientos
       └─ Eliminar pagos

    🏦 Ahorro
       ├─ Total acumulado
       └─ Historial por quincena

    ⚙️  Configuración
       ├─ Gestionar categorías
       ├─ Hacer respaldos
       └─ Cerrar sesión


6️⃣  ARCHIVOS IMPORTANTES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    📄 README.md
       Documentación completa de la app

    📄 GUIA_RAPIDA.md
       Guía paso a paso de uso

    📄 ARQUITECTURA.md
       Documentación técnica detallada

    📄 DATABASE_SCHEMA.md
       Esquema de base de datos

    📄 RESUMEN_FINAL.md
       Resumen ejecutivo del proyecto

    📁 data/
       Base de datos SQLite (se crea automáticamente)

    📁 backups/
       Respaldos automáticos de la BD


7️⃣  CARACTERÍSTICAS PRINCIPALES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    ✅ Multiusuario
       Múltiples usuarios en la misma app, datos aislados

    ✅ Presupuestos Quincenales
       Detecta automáticamente si es quincena 1 o 2

    ✅ Gastos Multi-Categoría
       Un gasto puede tener varias categorías

    ✅ Indicadores Visuales
       Barras de progreso con colores (verde/naranja/rojo)

    ✅ Ahorros Automáticos
       Calcula y registra automáticamente tu ahorro

    ✅ Respaldos Automáticos
       Copia segura de tus datos

    ✅ Pagos Fijos Fáciles
       Gestiona tus subscripciones


8️⃣  SOLUCIONAR PROBLEMAS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    ❌ "ModuleNotFoundError: No module named 'customtkinter'"
       Solución: pip install -r requirements.txt

    ❌ "La app no inicia"
       Solución: Verifica Python 3.8+ con: python --version

    ❌ "Base de datos bloqueada"
       Solución: Cierra la app y reinicia

    ❌ "Los datos desaparecieron"
       Solución: Restaura desde respaldos en la carpeta "backups/"


9️⃣  PRÓXIMOS PASOS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    1. Registra tus gastos diarios
    2. Monitorea tu presupuesto en el Dashboard
    3. Agrega tus pagos fijos/subscripciones
    4. Sigue tu ahorro hacia la meta del 45%
    5. Haz respaldos regularmente


🔟 CONTACTO Y SOPORTE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    Para dudas o problemas:
    1. Lee los archivos .md (documentación)
    2. Consulta los comentarios en el código
    3. Revisa la sección "Solucionar Problemas"


╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║          ¡Ya está todo listo! Ejecuta: python main.py                     ║
║                                                                            ║
║        Creado con ❤️ para ayudarte a alcanzar tu meta del 45% 🎯         ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝

"""

if __name__ == "__main__":
    print(__doc__)
    print("\n📍 Para comenzar, ejecuta:")
    print("   python main.py\n")
