# Contribuir a RBP

Gracias por tu interés en contribuir.

## Flujo recomendado

1. Haz un fork del repositorio.
2. Crea una rama de trabajo:
   - `feature/nombre-corto`
   - `fix/nombre-corto`
3. Haz cambios pequeños y enfocados.
4. Ejecuta validación local:

```bash
python -m py_compile main.py src/ui/flet_app.py src/db/database.py
```

5. Abre un Pull Request con:
   - Qué cambiaste
   - Cómo probarlo
   - Capturas (si es UI)

## Estándares

- Mantener estilo del código existente.
- Evitar cambios no relacionados con el problema.
- No subir artefactos de build (`dist/`, `build/`) ni base de datos local.
- Documentar cambios visibles al usuario en `README.md`.
