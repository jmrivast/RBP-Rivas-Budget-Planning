# GitHub Release Checklist - v2.0.0 (Windows)

Checklist operativo para publicar la version comercial inicial usando instalador **NSIS**.

## 1) Validacion tecnica previa

- [ ] Estar en branch `development`.
- [ ] `flutter analyze --no-pub` en `rbp_flutter`: OK.
- [ ] `flutter test --no-pub` en `rbp_flutter`: OK.
- [ ] `flutter build windows --release` en `rbp_flutter`: OK.

## 2) Empaquetado del instalador

- [ ] NSIS instalado:
  - `winget install -e --id NSIS.NSIS`
- [ ] Generar setup:
  - `powershell -ExecutionPolicy Bypass -File installer/build_nsis.ps1 -Version 2.0.0`
- [ ] Verificar artefacto:
  - `dist/RBP_Setup_2.0.0.exe`
- [ ] Generar checksum:
  - `Get-FileHash dist\RBP_Setup_2.0.0.exe -Algorithm SHA256`
- [ ] Guardar checksum en:
  - `dist/SHA256SUMS.txt`

## 3) Prueba de instalacion minima (smoke)

- [ ] Instalar en maquina limpia (o VM).
- [ ] Abrir app y verificar:
  - icono correcto
  - navegacion entre tabs
  - guardar un ingreso y un gasto
  - exportar PDF y CSV
- [ ] Desinstalar y reinstalar: OK.

## 4) Publicacion en GitHub Releases

- [ ] Crear tag `v2.0.0` desde commit estable en `development`.
- [ ] Publicar release title:
  - `RBP v2.0.0 (Windows)`
- [ ] Adjuntar assets:
  - `dist/RBP_Setup_2.0.0.exe`
  - `dist/SHA256SUMS.txt`
- [ ] Usar notas base desde:
  - `RELEASE_NOTES_2.0.0.md`

## 5) Post-publicacion

- [ ] Descargar el instalador desde GitHub Releases y ejecutar prueba final.
- [ ] Confirmar que el checksum publicado coincide.
- [ ] Guardar evidencia de entrega (cliente, version, fecha, checksum) en tu registro comercial.

