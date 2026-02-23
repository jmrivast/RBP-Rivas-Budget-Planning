# rbp_flutter

Flutter app de RBP enfocada en Windows desktop para distribucion comercial.

## Build de produccion (Windows)

```powershell
flutter build windows --release
```

Ejecutable generado:

`build/windows/x64/runner/Release/rbp_flutter.exe`

## Instalador recomendado

Usa Inno Setup con el script `installer/RBP_Setup.iss` en la raiz del repo.

## Estado del producto

- Objetivo actual: paridad total con la app legacy y distribucion en Windows.
- Android/Web: aplazado temporalmente hasta cerrar version comercial de Windows.
