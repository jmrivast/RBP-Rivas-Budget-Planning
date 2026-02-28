# Landing de Descarga - RBP

Esta carpeta contiene una pagina estatica lista para distribuir la app.

## Archivos

- `landing/index.html`
- `landing/styles.css`
- `landing/assets/logo.png`
- `landing/assets/instalacion-rbp.mp4`

## Publicar gratis (opcion 1: GitHub Pages)

1. Crea un repo solo para la web (ej: `rbp-download`).
2. Sube toda la carpeta `landing` (incluyendo `assets`).
3. En Settings -> Pages:
   - Source: `Deploy from a branch`
   - Branch: `main` (root)
4. Tu web quedara en `https://<usuario>.github.io/rbp-download/`

## Publicar gratis (opcion 2: Netlify)

1. Crea cuenta en Netlify.
2. Arrastra la carpeta `landing` al dashboard.
3. Netlify te da URL tipo `https://xxxx.netlify.app`.

## Personalizacion rapida

- Boton descarga principal: `index.html` (enlace de `RBP_Setup_2.0.0.exe`).
- WhatsApp y correo de soporte: seccion "Soporte y activacion".
- Video + miniatura: seccion "Video de instalacion" (`poster` y `src`).
