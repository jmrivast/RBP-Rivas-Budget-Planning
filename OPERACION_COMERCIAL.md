# Operacion Comercial Minima - RBP v2.x

Este documento define el proceso operativo base para vender y dar soporte a RBP en Windows.

## 1) Proceso de entrega de licencia

1. Solicitar al cliente el `Machine ID` mostrado en pantalla de activacion.
2. Generar la clave:
   - Comando: `dart run rbp_flutter/tools/generate_key.dart <MACHINE_ID>`
3. Entregar la clave por WhatsApp/email junto con instrucciones de activacion.
4. Confirmar activacion por captura o llamada corta.

## 2) Proceso de soporte basico

- Canal principal: WhatsApp o correo.
- Horario recomendado: 9:00 AM - 7:00 PM (hora local).
- SLA sugerido:
  - Problema bloqueante (no abre / no guarda): <= 24h.
  - Dudas de uso: <= 48h.
- Flujo:
  1. Pedir version app y captura del error.
  2. Pedir pasos para reproducir.
  3. Resolver o escalar a patch.

## 3) Politica de reinstalacion / cambio de PC

- Una licencia activa por equipo (atada al `Machine ID`).
- Reinstalacion en la misma PC: no requiere nueva licencia si el `Machine ID` no cambia.
- Cambio de PC:
  - Desactivar licencia anterior (si aplica) y emitir nueva clave para el nuevo `Machine ID`.
  - Registrar motivo del cambio.

## 4) Registro basico de clientes y licencias

Mantener un archivo (Excel/Google Sheet/Notion) con estas columnas:

- Fecha
- Nombre cliente
- Contacto
- Version entregada
- Machine ID
- Clave emitida
- Estado (Activa / Migrada / Revocada)
- Observaciones

## 5) Entrega estandar al cliente

1. Enviar instalador `RBP_Setup_2.0.0.exe`.
2. Enviar pasos:
   - Ejecutar instalador.
   - Abrir app.
   - Copiar `Machine ID`.
   - Pegar clave recibida y activar.
3. Hacer prueba guiada:
   - Agregar 1 ingreso.
   - Agregar 1 gasto.
   - Exportar 1 PDF.

