# Instalador NSIS - RBP v2.0.0

Este proyecto usa NSIS para generar el instalador de Windows:

- Script: `installer/RBP_Setup.nsi`
- Build helper: `installer/build_nsis.ps1`
- Salida: `dist/RBP_Setup_2.0.0.exe`

## Requisitos

1. Flutter release ya compilado:
   - `flutter build windows --release`
2. NSIS instalado:
   - `winget install -e --id NSIS.NSIS`

## Generar instalador

```powershell
powershell -ExecutionPolicy Bypass -File installer/build_nsis.ps1 -Version 2.0.0
```

## Validar

1. Ejecutar instalador y completar asistente.
2. Verificar acceso directo en escritorio y menu inicio.
3. Abrir la app y confirmar icono/carga normal.
4. Desinstalar desde "Aplicaciones instaladas" y reinstalar.
