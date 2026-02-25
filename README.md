# RBP - Rivas Budget Planning

Aplicacion de escritorio para control de finanzas personales en Windows.

## Descarga e instalacion (usuarios finales)

1. Ve a la seccion **Releases** de este repositorio.
2. Descarga el instalador `.exe` mas reciente.
3. Ejecuta el instalador y sigue el asistente: `Siguiente > Siguiente > Instalar`.
4. Abre la app desde el acceso directo de escritorio o menu inicio.

Notas:
- Version estable actual: `2.0.0`.
- Si Windows muestra advertencia de seguridad, valida que el archivo sea `RBP_Setup_2.0.0.exe`.

## Build de instalador (equipo de desarrollo)

El instalador comercial de Windows usa **NSIS** (no Inno Setup).

1. Compila app release:
   - `flutter build windows --release`
2. Instala NSIS (una sola vez):
   - `winget install -e --id NSIS.NSIS`
3. Genera instalador:
   - `powershell -ExecutionPolicy Bypass -File installer/build_nsis.ps1 -Version 2.0.0`
4. Resultado:
   - `dist/RBP_Setup_2.0.0.exe`

## Requisitos

- Windows 10 u 11 (64-bit)

## Funciones principales

- Resumen financiero por periodo
- Modo quincenal o mensual
- Ingresos, gastos, pagos fijos, prestamos y ahorro
- Exportacion a PDF y CSV
- Respaldo y restauracion
- Configuracion de categorias

## Actualizaciones

- Las nuevas versiones se publican en **Releases**.
- Se recomienda instalar siempre la ultima version estable.
- Cambios de esta version: ver `RELEASE_NOTES_2.0.0.md`.

## Soporte

Para soporte tecnico o activacion/licencia, usa los contactos mostrados dentro de la app.
Operacion comercial y politica de licencias: `OPERACION_COMERCIAL.md`.

## Nota de distribucion del repositorio

Este repositorio se usa como canal de distribucion de binarios para usuarios finales.

## Licencia

Este software se distribuye bajo licencia propietaria.
Consulta el archivo `LICENSE`.
