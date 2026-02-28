# RBP v2.0.1 (Windows) - Release Notes

Fecha: 2026-02-28

## Resumen

Release de mantenimiento para mejorar la coherencia de actualizaciones y corregir calculos en PDF.

## Cambios principales

- Actualizaciones:
  - El boton de actualizacion ahora abre la pagina del release (no descarga automatica del setup).
  - Texto del boton actualizado a `Abrir descarga` para evitar confusion.
- Reporte PDF:
  - Corregido el total de `Prestamos pend.` en el resumen para que coincida con la tabla de prestamos pendientes.
- Versionado:
  - App actualizada a `2.0.1+1`.
  - Empaquetado MSIX actualizado a `2.0.1.0`.
- Instalador NSIS:
  - Nuevo instalador: `RBP_Setup_2.0.1.exe`.

## QA y build

- `flutter analyze --no-pub`: OK
- `flutter build windows --release`: OK
- Instalador NSIS compilado: OK
