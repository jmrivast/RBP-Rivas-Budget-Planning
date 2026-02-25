# Release Checklist - RBP v2.0 (Windows)

Este checklist define el criterio **Go/No-Go** para vender la app Flutter (v2.0) a familiares y conocidos.

## 1. Alcance de esta release

- Plataforma objetivo: Windows 10/11 x64.
- Canal: instalador `.exe` (NSIS).
- Versionado: `2.0.0` (primera release Flutter luego de la serie Python/Flet `1.x`).

## 2. Bloqueantes de salida (deben estar 100% completos)

- [x] Paridad PDF con la app anterior (layout + datos + flujo de apertura).
- [x] Fluidez estable al navegar pantallas (sin congelamientos perceptibles).
- [x] UI final congelada (sin cambios visuales pendientes).
- [x] Exportes PDF/CSV validados en Windows.
- [x] Backup y restauracion validados con datos reales.
- [x] Activacion/licencia validada de extremo a extremo.

## 3. QA funcional minimo (smoke + regresion)

- [x] Resumen: metricas correctas por periodo.
- [x] Ingresos: guardar/editar/eliminar funciona.
- [x] Nuevo gasto: guardar/editar/eliminar funciona.
- [x] Pagos fijos: alta/edicion/marcado pagado/pendiente funciona.
- [x] Prestamos: alta/edicion/pago funciona.
- [x] Ahorro: depositar/retirar/meta funciona.
- [x] Configuracion: modo mensual/quincenal, dias de cobro, categorias.
- [x] Cierre de periodo: exportacion automatica segun configuracion.

## 4. QA tecnico (must pass)

- [x] `flutter analyze --no-pub` sin errores.
- [x] `flutter test --no-pub` 100% verde.
- [x] `flutter build windows --release` sin errores.
- [x] Instalador generado sin errores (`makensis`).
- [x] Instalacion limpia en una PC/VM sin entorno de desarrollo.
- [x] Desinstalar y reinstalar conserva comportamiento esperado.

## 5. Empaquetado y distribucion

- [x] Publicar `RBP_Setup_2.0.0.exe` en Releases.
- [x] Nota de version clara (que cambia en v2.0).
- [x] Instrucciones de instalacion para usuario final en README.
- [x] Verificar que `main` solo tenga artefactos de distribucion (sin codigo fuente).

## 6. Operacion comercial minima

- [x] Proceso de entrega de licencia (quien genera y como se entrega).
- [x] Proceso de soporte basico (contacto y tiempos de respuesta).
- [x] Politica simple de reinstalacion/cambio de PC.
- [x] Registro basico de clientes/licencias emitidas.

## 7. Criterio Go / No-Go

- **GO**: todos los checks de secciones 2, 4 y 5 completos.
- **NO-GO**: cualquier item bloqueante abierto.

Estado actual: **GO**.

## 8. Plan inmediato (orden recomendado)

1. Cerrar PDF 1:1 (layout y datos).
2. Congelar UI final.
3. Pasada de rendimiento.
4. QA manual completa + correcciones.
5. Build release + instalador final + publicacion.

## 9. Evidencia de cierre (2026-02-23)

- `flutter analyze --no-pub`: OK
- `flutter test --no-pub`: OK (27 tests)
- `flutter build windows --release`: OK
- Instalador NSIS compilado: `dist/RBP_Setup_2.0.0.exe`
- Instalacion silenciosa: OK
- Desinstalacion silenciosa: OK
- Reinstalacion silenciosa: OK

## 10. Evidencia migracion instalador a NSIS (2026-02-25)

- NSIS instalado via `winget`: OK
- Script de instalador creado: `installer/RBP_Setup.nsi`
- Script de build reproducible: `installer/build_nsis.ps1`
- Compilacion NSIS: OK (`dist/RBP_Setup_2.0.0.exe`)
- Instalacion silenciosa NSIS: OK
- Desinstalacion silenciosa NSIS: OK
