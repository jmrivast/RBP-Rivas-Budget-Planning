# RBP - Rivas Budget Planning

Aplicación de escritorio local para finanzas personales hecha con Flet + SQLite.

## Qué incluye

- Dashboard con navegación por período.
- Modo de trabajo **quincenal** o **mensual**.
- Gestión de ingresos, gastos, pagos fijos, préstamos y ahorro.
- Categorías personalizables desde **Configuración** (crear, renombrar, eliminar).
- Exportación a PDF y CSV.
- Exportación automática al cierre de período (opcional).
- Respaldo y restauración desde la app.

## Requisitos

- Python 3.10+
- Windows 10/11 (principal objetivo de empaquetado)

## Instalación local (desarrollo)

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

Opcional (datos iniciales):

```bash
python init_sample_data.py
```

## Uso rápido

1. En **Configuración**, elige la frecuencia (`Quincenal` o `Mensual`).
2. Define salario base y, si aplica, salario por quincena.
3. Registra ingresos/gastos y revisa el resumen.
4. Exporta manualmente con botones `PDF` / `CSV` o activa la exportación automática.

## Configuración en la app

En la pestaña **Configuración** puedes:

- Cambiar frecuencia de reporte/salario.
- Activar/desactivar exportación automática al cierre de período.
- Crear respaldo manual.
- Restaurar último respaldo.
- Administrar categorías (agregar, renombrar, eliminar).

## Respaldos y restauración

- Los respaldos se guardan en `backups/`.
- “Crear respaldo” copia la BD actual con timestamp.
- “Restaurar último respaldo” reemplaza la BD actual por el más reciente.

Recomendación: antes de restaurar, cerrar la app en otras ventanas/procesos.

## Estructura principal

```text
src/
  config.py
  db/database.py
  ui/flet_app.py
  utils/backup.py
main.py
requirements.txt
```

## Build para compartir (Windows)

### Opción recomendada: onedir

```bash
python -m PyInstaller --noconfirm --clean --noupx --onedir --windowed --name RBP_onedir --icon=icon.ico --add-data "Untitled.png;." --add-data "icon.ico;." main.py
```

Salida:

- `dist/RBP_onedir/RBP_onedir.exe`

## Descarga para usuarios finales

- Los ejecutables para tus amigos se publican en **GitHub Releases** (no dentro del código fuente del repo).
- Release actual: `v1.0.0` en la pestaña *Releases*.

## Antivirus y falsos positivos (Windows)

Para reducir falsos positivos con PyInstaller:

- Usa `--onedir` (menos sospechoso que `--onefile` en muchos motores).
- Usa `--noupx` para evitar compresión de binarios.
- Usa `--clean` para builds reproducibles.
- Evita renombrar el `.exe` en cada build sin necesidad.
- Firma digitalmente el ejecutable (code-signing) cuando sea posible.
- Si aparece un falso positivo, reporta el hash del binario al proveedor antivirus (por ejemplo, Microsoft Defender).

### Empaquetar en ZIP para enviar

```powershell
Compress-Archive -Path .\dist\RBP_onedir\* -DestinationPath .\dist\RBP_onedir.zip -Force
```

## Variables de entorno (opcionales)

Copia `.env.example` a `.env` y ajusta SMTP si usarás notificaciones por email.

## Publicar en GitHub

1. Inicializa git en la carpeta del proyecto.
2. Crea repositorio en GitHub.
3. Sube el código (sin `dist/`, `build/`, `data/finanzas.db`, `backups/`, gracias a `.gitignore`).

Comandos base:

```bash
git init
git add .
git commit -m "Initial release"
git branch -M main
git remote add origin <TU_REPO_URL>
git push -u origin main
```

## Notas

- `src/ui/app.py` y `src/ui/frames/` son legado (CustomTkinter).
- La entrada activa del proyecto actual es `main.py` -> `src/ui/flet_app.py`.

## Licencia

MIT. Ver `LICENSE`.
