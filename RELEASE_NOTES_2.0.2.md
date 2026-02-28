# RBP v2.0.2 (Windows) - Release Notes

Fecha: 2026-02-28

## Resumen

Release enfocada en hacer la actualizacion mucho mas automatica para el usuario final en Windows.

## Cambios principales

- Auto-actualizacion en Windows (flujo 1 clic):
  - Descarga instalador del release automaticamente.
  - Ejecuta instalacion silenciosa (`/S`).
  - Cierra y vuelve a abrir la app al terminar.
- Dialogo de update mejorado:
  - Nuevo boton `Actualizar ahora`.
  - Opcion `Ver release` como fallback manual.
- Servicio de updates:
  - Ahora resuelve URL de pagina de release y URL directa del instalador por separado.
  - Prioriza assets `setup*.exe` para auto-update.

## QA y build

- `flutter analyze --no-pub`: OK
- `flutter build windows --release`: OK
- Instalador NSIS compilado: OK (`RBP_Setup_2.0.2.exe`)
