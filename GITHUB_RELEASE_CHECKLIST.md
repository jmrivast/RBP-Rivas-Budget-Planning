# Checklist de publicación (GitHub)

## 1) Verificación local

- [ ] App abre sin errores (`python main.py`)
- [ ] Compilación sintáctica OK
- [ ] Funciones clave probadas (gastos, ingresos, configuración, exportación)

## 2) Limpieza

- [ ] No incluir `dist/`, `build/`, `.venv/`
- [ ] No incluir `data/finanzas.db` real
- [ ] No incluir respaldos reales en `backups/`

## 3) Documentación

- [ ] `README.md` actualizado
- [ ] `LICENSE` presente
- [ ] `.env.example` limpio
- [ ] `CONTRIBUTING.md` presente

## 4) Publicar repositorio

```bash
git init
git add .
git commit -m "Initial release"
git branch -M main
git remote add origin <TU_REPO_URL>
git push -u origin main
```

## 5) Publicar release con ejecutable

- [ ] Generar build onedir
- [ ] Comprimir carpeta a ZIP
- [ ] Crear Release en GitHub
- [ ] Adjuntar ZIP y notas de versión
