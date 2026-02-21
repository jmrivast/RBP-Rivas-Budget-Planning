# Guía Rápida - Gestor de Finanzas Personal

## 🚀 Inicio Rápido

### 1. Instalación (Primera vez)

```bash
# Navega a la carpeta del proyecto
cd finanzas_app

# Instala las dependencias
pip install -r requirements.txt

# (Opcional) Carga datos de prueba
python init_sample_data.py

# Ejecuta la app
python main.py
```

### 2. Primera sesión

1. **Abre la aplicación** ejecutando `python main.py`
2. **Crea un nuevo usuario** ingresando tu nombre y haciendo clic en "Crear Nuevo Usuario"
3. **Las categorías se crean automáticamente:**
   - Comida
   - Combustible
   - Uber/Taxi
   - Subscripciones
   - Varios/Snacks
   - Otros

---

## 📊 Panel Principal (Dashboard)

### ¿Qué ves aquí?

El Dashboard muestra tu presupuesto y gastos por quincena:

```
┌─────────────────────────────────────────────────┐
│           1ª Quincena - Febrero 2026            │
├─────────────────────────────────────────────────┤
│                                                 │
│ Comida                    RD$500 / RD$2,750     │
│ [████░░░░░░░░░░░░░░░] 18.2%                   │
│                                                 │
│ Combustible              RD$1,200 / RD$3,500    │
│ [██████░░░░░░░░░░░] 34.3%                     │
│                                                 │
│ ...                                            │
├─────────────────────────────────────────────────┤
│ Disponible para gastar: RD$15,200.00           │
│ Ahorro Acumulado: RD$22,500.00                 │
└─────────────────────────────────────────────────┘
```

### Colores de las Barras

- 🟢 **Verde** (≤50%): Gastos bajo control
- 🟠 **Naranja** (50-80%): Atención, se está acabando
- 🔴 **Rojo** (>80%): ¡Cuidado! Presupuesto casi agotado

### Navegar entre Quincenas

- **← Anterior**: Ir a la quincena anterior
- **Siguiente →**: Ir a la siguiente quincena

---

## 💰 Registrar Gastos

### Formulario

1. **Monto**: Ingresa la cantidad en RD$ (ej: 250.50)
2. **Descripción**: Qué compraste (ej: "McDonald's - Almuerzo")
3. **Fecha**: Por defecto es hoy, pero puedes cambiarla
4. **Categorías**: Selecciona una o más (ej: "Comida" + "Otros")
5. **Estado**:
   - **Saldado**: El gasto ya se pagó (se cuenta en el presupuesto)
   - **Pendiente**: Gasto que aún no pagas (se reserva pero no cuenta)

### Ejemplo

```
Monto: 350.00
Descripción: Comida en restaurante
Fecha: 2026-02-11
Categorías: ✓ Comida
Estado: Saldado
```

---

## 🔁 Pagos Fijos (Subscripciones)

### ¿Qué son?

Gastos que se repiten cada mes en la misma fecha:
- Netflix (RD$270 cada mes)
- Spotify (RD$150 cada mes)
- Gym (RD$500 cada mes)

### Cómo agregar un pago fijo

1. Ve a **"Pagos Fijos"** en la barra lateral
2. Completa:
   - **Nombre**: Netflix
   - **Monto**: 270.00
   - **Día de Vencimiento**: 15 (se paga cada mes el 15)
   - **Categoría**: Subscripciones (opcional)
3. Haz clic en **"Agregar Pago Fijo"**

### ¿Cómo sé cuándo pagar?

La app te mostrará qué pagos vencen pronto y te enviará recordatorios por email (si configuras tus credenciales en `.env`).

---

## 💵 Mi Ahorro

### ¿Qué ves aquí?

- **Ahorro Total Acumulado**: Todo lo que has ahorrado hasta hoy
- **Meta**: RD$7,500 por quincena
- **Historial**: Registro de ahorros por quincena

### Cómo funciona el ahorro

1. Al finalizar cada quincena, la app calcula automáticamente cuánto ahorraste
2. Si tu presupuesto total era RD$16,579 y gastaste RD$9,079, el ahorro de esa quincena es RD$7,500
3. Este monto se suma a tu ahorro acumulado

### Meta 45%

- Sueldo: RD$33,158
- Ahorro mensual (meta): 45% = RD$14,921 (RD$7,500 por quincena)
- Disponible para gastar: 55% = RD$18,237 (RD$9,119 por quincena)

---

## ⚙️ Configuración

### Gestionar Categorías

1. Ve a **"Configuración"** en la barra lateral
2. Verás todas tus categorías
3. Puedes:
   - **Agregar nueva**: Haz clic en "+ Agregar Categoría"
   - **Eliminar**: Haz clic en "Eliminar" junto a la categoría

### Hacer un Respaldo

1. En **"Configuración"**, haz clic en **"Hacer Respaldo"**
2. Se crea automáticamente un archivo en la carpeta `backups/`
3. Puedes restaurar desde un respaldo si algo sale mal

### Cerrar Sesión

Haz clic en **"Cerrar Sesión"** para volver a la pantalla de login.

---

## 📱 Notificaciones por Email (Opcional)

### Configurar

1. Abre `.env` en la carpeta del proyecto
2. Llena tus credenciales de Gmail:

```
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
EMAIL_SENDER=tu_email@gmail.com
EMAIL_PASSWORD=tu_password_app
```

3. **Generar contraseña de app en Gmail:**
   - Ve a [myaccount.google.com](https://myaccount.google.com)
   - Seguridad → Acceso a dispositivos menos seguros
   - Genera una contraseña de aplicación

### ¿Qué notificaciones recibirás?

- ⚠️ Cuando un presupuesto llegue al 80%
- 📢 Recordatorio de pagos fijos próximos
- ✅ Confirmación de respaldos

---

## 🐛 Solucionar Problemas

### La app no inicia

```bash
# Verifica que Python 3.8+ esté instalado
python --version

# Reinstala las dependencias
pip install -r requirements.txt --force-reinstall

# Intenta ejecutar nuevamente
python main.py
```

### Error "Base de datos está bloqueada"

- Cierra todas las instancias de la app
- Elimina archivos `.db-journal` en la carpeta `data/`
- Abre la app nuevamente

### Los datos desaparecieron

1. Verifica si hay un respaldo en `backups/`
2. En Configuración, haz clic en "Restaurar Respaldo"
3. Si no hay respaldo, lamentablemente los datos se perdieron

### La app se ve pixelada

- CustomTkinter funciona mejor en pantallas de alta resolución
- Intenta cambiar la escala de tu sistema operativo

---

## 📊 Consejos de Uso

### 1. Registra gastos constantemente

No esperes a fin de mes. Registra cada compra el mismo día para evitar olvidar.

### 2. Usa múltiples categorías si es necesario

Ejemplo: Compra en supermercado → "Comida" + "Varios"

### 3. Revisa el Dashboard cada día

Tener visibilidad diaria de tu presupuesto te ayudará a tomar mejores decisiones.

### 4. Ajusta presupuestos según necesidad

Si cierto mes gastaste más en combustible, aumenta el presupuesto para el mes siguiente.

### 5. Haz respaldos regularmente

La app hace respaldos automáticos, pero también puedes hacerlo manualmente desde Configuración.

---

## 🎯 Ejemplo de Flujo Completo

### Día 11 de febrero

```
1. Abro la app
2. Veo el Dashboard: "Quincena 1 - Febrero 2026"
3. Mi presupuesto de comida: RD$2,750
4. He gastado: RD$500 (18%)
5. Disponible en comida: RD$2,250

6. Voy a McDonald's y gasto RD$250
7. Voy a "Registrar Gasto":
   - Monto: 250
   - Descripción: McDonald's
   - Categoría: Comida
   - Estado: Saldado
8. Hago clic en "Guardar Gasto"

9. Vuelvo al Dashboard
10. Mi gasto en comida ahora es: RD$750 (27%)
11. Disponible en comida: RD$2,000
```

---

## 📞 Soporte

Para reportar bugs o tener dudas:
1. Revisa la sección "Solucionar Problemas" arriba
2. Consulta el `README.md` para más información técnica
3. Si nada funciona, elimina `data/finanzas.db` y comienza de nuevo

---

**¡Gracias por usar el Gestor de Finanzas Personal! 🚀**

*Recuerda: El ahorro del 45% es totalmente posible con disciplina y visibilidad de tus gastos.*
