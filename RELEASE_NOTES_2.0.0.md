# RBP v2.0.0 (Windows) - Release Notes

Fecha: 2026-02-23

## Resumen

Primera version comercial en Flutter para Windows, sucesora de la linea 1.x en Python/Flet.

## Cambios principales

- Migracion completa de app desktop a Flutter.
- Migracion del empaquetado de instalador a NSIS (flujo comercial sin Inno Setup).
- Paridad funcional de modulos:
  - Resumen
  - Ingresos
  - Nuevo gasto
  - Pagos fijos
  - Prestamos
  - Ahorro
  - Configuracion
- Exportes PDF y CSV integrados.
- Respaldo y restauracion de base de datos.
- Activacion por licencia por equipo.
- Instalador NSIS (`RBP_Setup_2.0.0.exe`).

## Estabilidad y rendimiento (v2.0.0)

- Ajustes de calculo en dashboard/PDF para evitar inconsistencia de montos.
- Prestamos con tipo de descuento (`ninguno`, `gasto`, `ahorro`) con impacto correcto en metricas.
- Edicion de pagos fijos ahora permite cambiar a "sin fecha fija".
- Correccion de overflow vertical en pantalla de ahorro.
- Navegacion entre pestañas optimizada con preservacion de estado para experiencia mas fluida.

## QA y build

- `flutter analyze --no-pub`: OK
- `flutter test --no-pub`: OK
- `flutter build windows --release`: OK
- Instalador NSIS compilado: OK
- Instalacion, desinstalacion y reinstalacion silenciosa: OK
