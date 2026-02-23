# Release Checklist - RBP v2.0 (Windows)

Este checklist define el criterio **Go/No-Go** para vender la app Flutter (v2.0) a familiares y conocidos.

## 1. Alcance de esta release

- Plataforma objetivo: Windows 10/11 x64.
- Canal: instalador `.exe` (Inno Setup).
- Versionado: `2.0.0` (primera release Flutter luego de la serie Python/Flet `1.x`).

## 2. Bloqueantes de salida (deben estar 100% completos)

- [ ] Paridad PDF con la app anterior (layout + datos + flujo de apertura).
- [ ] Fluidez estable al navegar pantallas (sin congelamientos perceptibles).
- [ ] UI final congelada (sin cambios visuales pendientes).
- [ ] Exportes PDF/CSV validados en Windows.
- [ ] Backup y restauracion validados con datos reales.
- [ ] Activacion/licencia validada de extremo a extremo.

## 3. QA funcional minimo (smoke + regresion)

- [ ] Resumen: metricas correctas por periodo.
- [ ] Ingresos: guardar/editar/eliminar funciona.
- [ ] Nuevo gasto: guardar/editar/eliminar funciona.
- [ ] Pagos fijos: alta/edicion/marcado pagado/pendiente funciona.
- [ ] Prestamos: alta/edicion/pago funciona.
- [ ] Ahorro: depositar/retirar/meta funciona.
- [ ] Configuracion: modo mensual/quincenal, dias de cobro, categorias.
- [ ] Cierre de periodo: exportacion automatica segun configuracion.

## 4. QA tecnico (must pass)

- [x] `flutter analyze --no-pub` sin errores.
- [x] `flutter test --no-pub` 100% verde.
- [x] `flutter build windows --release` sin errores.
- [x] Instalador generado sin errores (`ISCC`).
- [ ] Instalacion limpia en una PC/VM sin entorno de desarrollo.
- [ ] Desinstalar y reinstalar conserva comportamiento esperado.

## 5. Empaquetado y distribucion

- [ ] Publicar `RBP_Setup_2.0.0.exe` en Releases.
- [ ] Nota de version clara (que cambia en v2.0).
- [ ] Instrucciones de instalacion para usuario final en README.
- [ ] Verificar que `main` solo tenga artefactos de distribucion (sin codigo fuente).

## 6. Operacion comercial minima

- [ ] Proceso de entrega de licencia (quien genera y como se entrega).
- [ ] Proceso de soporte basico (contacto y tiempos de respuesta).
- [ ] Politica simple de reinstalacion/cambio de PC.
- [ ] Registro basico de clientes/licencias emitidas.

## 7. Criterio Go / No-Go

- **GO**: todos los checks de secciones 2, 4 y 5 completos.
- **NO-GO**: cualquier item bloqueante abierto.

## 8. Plan inmediato (orden recomendado)

1. Cerrar PDF 1:1 (layout y datos).
2. Congelar UI final.
3. Pasada de rendimiento.
4. QA manual completa + correcciones.
5. Build release + instalador final + publicacion.
