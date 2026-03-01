# RBP v2.x Feature Backlog (Private Development)

Este backlog se trabaja en `development-private` (remote: `private`) para no impactar la versión pública estable.

## Criterio de prioridad
- `P0`: impacta ventas/retención inmediata.
- `P1`: mejora fuerte del producto, pero puede salir después.
- `P2`: valor incremental.

## Backlog priorizado

| Prioridad | Feature | Impacto negocio | Complejidad | Estado |
|---|---|---|---|---|
| P0 | Perfiles múltiples (finanzas separadas por persona/cuenta) + PIN 4/6 dígitos | Muy alto | Alta | Pendiente |
| P0 | Base freemium (Plan Free/Pro + feature flags locales) | Muy alto | Media | Pendiente |
| P0 | Deudas bancarias (entidad nueva) con tasa, plazo y cuota estimada | Muy alto | Alta | Pendiente |
| P0 | Registro de pagos a capital/interés en deudas | Muy alto | Alta | Pendiente |
| P0 | Notificaciones y alertas locales (vencimientos, cierre de período) | Alto | Media | Pendiente |
| P0 | Pagos fijos: posponer X días + marcar "no pagado" en pagos con fecha fija | Alto | Media | Pendiente |
| P1 | Moneda configurable (símbolo/formato) | Medio-Alto | Media | Pendiente |
| P1 | Personalización de colores por usuario (tema base + acentos) | Medio | Media | Pendiente |
| P1 | Panel de pagos fijos: total quincena + total mes | Alto | Baja | Pendiente |
| P1 | Mostrar versión actual y canal en Configuración | Medio | Baja | Pendiente |
| P1 | Botón "Abrir carpeta de reportes" en Configuración | Medio | Baja | Pendiente |
| P1 | Mejoras de auto-update (rollback, errores de descarga, logs usuario) | Alto | Media | Pendiente |
| P2 | Dashboard histórico avanzado (Power BI embebido o dashboard interno) | Medio | Alta | Pendiente |
| P2 | Onboarding interactivo visual (flechas/tooltips) versión estable | Medio | Alta | Pendiente |

## Orden recomendado de implementación (sprints)

### Sprint 1 (ventas + arquitectura base)
1. Perfiles múltiples + PIN.
2. Base freemium (flags + bloqueo de features Pro).
3. Pagos fijos: posponer y marcar no pagado.

### Sprint 2 (finanzas avanzadas)
1. Deudas bancarias (modelo + UI + cálculo cuota).
2. Pagos a capital/interés.
3. Totales quincena/mes en pagos fijos.

### Sprint 3 (UX + escalado)
1. Moneda configurable.
2. Personalización de colores.
3. Notificaciones locales completas.

## Notas de implementación
- Evitar romper compatibilidad con datos actuales (`SQLite migrations` obligatorias).
- Toda feature nueva debe incluir:
  - migración DB,
  - validación de edge cases,
  - pruebas manuales en Windows,
  - feature flag si impacta flujo crítico.
