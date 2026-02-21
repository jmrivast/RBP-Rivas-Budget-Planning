# SignPath Foundation (gratis) para RBP

Esta guía deja firma automática de Releases en GitHub para reducir falsos positivos.

## 1) Requisitos

- Repositorio público (ya cumplido).
- Cuenta GitHub del propietario (ya cumplido).
- Cuenta en SignPath con acceso a **SignPath Foundation** para open-source.

## 2) Alta en SignPath

1. Crea cuenta en SignPath.
2. Solicita/activa plan Foundation para proyecto open-source.
3. Crea una Organization y un Project para `RBP-Rivas-Budget-Planning`.
4. Crea o identifica:
   - `organization-id`
   - `project-slug`
   - `signing-policy-slug`
5. Genera un API token para usuario con permiso de submitter.

## 3) Conectar GitHub con SignPath

1. Instala la app de GitHub de SignPath: https://github.com/apps/signpath
2. Otorga acceso al repo `jmrivast/RBP-Rivas-Budget-Planning`.
3. En SignPath, configura Trusted Build System para GitHub.com y enlázalo al proyecto.

## 4) Configurar secrets del repositorio (GitHub)

En GitHub -> Settings -> Secrets and variables -> Actions -> New repository secret:

- `SIGNPATH_API_TOKEN`
- `SIGNPATH_ORGANIZATION_ID`
- `SIGNPATH_PROJECT_SLUG`
- `SIGNPATH_SIGNING_POLICY_SLUG`

## 5) Workflow ya incluido

Archivo: `.github/workflows/release-signpath.yml`

Qué hace:

1. Compila app Windows con PyInstaller (`onedir`, `clean`, `noupx`).
2. Sube ZIP unsigned como artifact del workflow.
3. Envía artifact a SignPath para firma.
4. Descarga artifact firmado.
5. Publica en la Release:
   - `RBP-Windows-Portable-signed.zip`
   - `SHA256SUMS.txt`

## 6) Cómo ejecutarlo

- Opción A: crear una Release nueva en GitHub (trigger automático).
- Opción B: ejecutar manualmente el workflow en Actions (`workflow_dispatch`).

## 7) Reportar falso positivo (Defender)

Con cada release firmada, usa los hashes de `SHA256SUMS.txt` y reporta en:

https://www.microsoft.com/en-us/wdsi/filesubmission

Incluye:

- archivo firmado (`RBP-Windows-Portable-signed.zip`),
- hash SHA256,
- enlace de la release,
- nombre de detección del antivirus.
