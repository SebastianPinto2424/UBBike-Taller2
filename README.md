# UBBike

Aplicacion web/mobile y API REST para registrar bicicletas, validar ingresos y retiros en bicicleteros, y mantener trazabilidad operativa para la Universidad del Bio-Bio.

Este README corresponde a la rama de despliegue con Docker Compose. Se enfoca en levantar el stack de produccion y compilar la APK contra la URL publicada del backend.

## Stack de produccion

El archivo `docker-compose.yml` levanta cuatro servicios:

| Servicio | Funcion | Puerto interno |
| --- | --- | --- |
| `db` | PostgreSQL 16, persistido en volumen Docker | `5432` |
| `redis` | Redis para limitador de intentos | `6379` |
| `backend` | API REST Node.js/Express, Prisma, Socket.IO y uploads | `3000` |
| `frontend` | Flutter Web servido con Nginx | `8080` |

El backend ejecuta automaticamente las migraciones Prisma al iniciar:

```bash
npm run migrate && node dist/servidor.js
```

Si `SEED_DEMO_DATA=true`, tambien se cargan datos demo al iniciar el backend.

## Arquitectura resumida

Backend modular por features:

```text
backend/src/
  comun/           middlewares, errores y utilidades
  configuracion/   entorno, Prisma, Redis, Firebase, Swagger y seed
  modulos/
    autenticacion/ usuarios/ bicicletas/ bicicleteros/
    acceso/ historial/ incidencias/ notificaciones/ qr/
  tiempo-real/     Socket.IO
```

Cada modulo mantiene la separacion:

```text
rutas -> controlador -> servicio -> repositorio
```

Mobile/Web usa estructura feature-first con Riverpod:

```text
mobile/lib/
  core/       configuracion, tema, providers y cliente HTTP
  features/   pantallas, view models, APIs y repositorios por feature
  shared/     widgets, modelos y utilidades transversales
```

## Variables de entorno para Docker Compose

Copia la plantilla y ajusta los valores reales:

```bash
cp .env.example .env
```

En Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

## Parametros de despliegue

Antes del despliegue se definen los datos de acceso al servidor y las URLs publicas de la aplicacion:

| Parametro | Funcion | Donde se configura |
| --- | --- | --- |
| Usuario SSH | Entrar al servidor | `ssh -p <PUERTO_SSH> <USUARIO>@<IP_O_HOST_SSH>` |
| IP o host SSH | Entrar al servidor | Comando `ssh` |
| Puerto SSH | Entrar al servidor | `-p <PUERTO_SSH>` |
| IP o host publico de la aplicacion | URL usada por navegador y dispositivos moviles | `PUBLIC_API_BASE_URL`, `PUBLIC_WS_BASE_URL`, `DOCKER_FRONTEND_URL`, `DOCKER_CORS_ORIGINS` y APK |
| Puerto backend en el servidor | Puerto que Docker abre en el servidor | `BACKEND_PORT` |
| Puerto frontend en el servidor | Puerto que Docker abre en el servidor | `FRONTEND_PORT` |
| Puerto backend publico | API REST, WebSocket, imagenes y `/salud` | `PUBLIC_API_BASE_URL`, `PUBLIC_WS_BASE_URL` y APK |
| Puerto frontend visible desde el navegador | Flutter Web | `DOCKER_FRONTEND_URL`, `DOCKER_CORS_ORIGINS` |

En el archivo `.env` se ajustan estas lineas:

```env
BACKEND_PORT=<PUERTO_BACKEND_EN_SERVIDOR>
FRONTEND_PORT=<PUERTO_FRONTEND_EN_SERVIDOR>

PUBLIC_API_BASE_URL=http://<IP_O_HOST_VISIBLE>:<PUERTO_BACKEND_VISIBLE>
PUBLIC_WS_BASE_URL=ws://<IP_O_HOST_VISIBLE>:<PUERTO_BACKEND_VISIBLE>
DOCKER_FRONTEND_URL=http://<IP_O_HOST_VISIBLE>:<PUERTO_FRONTEND_VISIBLE>
DOCKER_CORS_ORIGINS=http://<IP_O_HOST_VISIBLE>:<PUERTO_FRONTEND_VISIBLE>
```

Ejemplo ficticio:

```env
BACKEND_PORT=3000
FRONTEND_PORT=8081
PUBLIC_API_BASE_URL=http://<IP_DEL_CONTENEDOR>:3000
PUBLIC_WS_BASE_URL=ws://<IP_DEL_CONTENEDOR>:3000
DOCKER_FRONTEND_URL=http://<IP_DEL_CONTENEDOR>:8081
DOCKER_CORS_ORIGINS=http://<IP_DEL_CONTENEDOR>:8081
```

Si el servidor publica directamente los mismos puertos disponibles por acceso externo, `BACKEND_PORT` coincide con el puerto backend publico y `FRONTEND_PORT` coincide con el puerto frontend publico.

Si existe NAT o mapeo de puertos externos distinto al puerto publicado por Docker, se separan los valores internos y publicos:

```env
BACKEND_PORT=<PUERTO_BACKEND_EN_SERVIDOR>
FRONTEND_PORT=<PUERTO_FRONTEND_EN_SERVIDOR>
PUBLIC_API_BASE_URL=http://<IP_O_HOST_VISIBLE>:<PUERTO_BACKEND_VISIBLE_DESDE_CELULAR>
PUBLIC_WS_BASE_URL=ws://<IP_O_HOST_VISIBLE>:<PUERTO_BACKEND_VISIBLE_DESDE_CELULAR>
DOCKER_FRONTEND_URL=http://<IP_O_HOST_VISIBLE>:<PUERTO_FRONTEND_VISIBLE_DESDE_NAVEGADOR>
DOCKER_CORS_ORIGINS=http://<IP_O_HOST_VISIBLE>:<PUERTO_FRONTEND_VISIBLE_DESDE_NAVEGADOR>
```

Ejemplo: si Docker publica el backend en `3000`, pero el acceso externo usa `1641`, la APK debe apuntar a `http://<IP>:1641`, no a `http://<IP>:3000`.

Variables principales:

```env
POSTGRES_DB=ubbike
POSTGRES_USER=ubbike
POSTGRES_PASSWORD=<PASSWORD_POSTGRES>
POSTGRES_PORT=5432

BACKEND_BIND_ADDRESS=0.0.0.0
BACKEND_PORT=<PUERTO_BACKEND_EN_SERVIDOR>
FRONTEND_BIND_ADDRESS=0.0.0.0
FRONTEND_PORT=<PUERTO_FRONTEND_EN_SERVIDOR>

PUBLIC_API_BASE_URL=http://<IP_O_HOST_VISIBLE>:<PUERTO_BACKEND_VISIBLE>
PUBLIC_WS_BASE_URL=ws://<IP_O_HOST_VISIBLE>:<PUERTO_BACKEND_VISIBLE>
DOCKER_FRONTEND_URL=http://<IP_O_HOST_VISIBLE>:<PUERTO_FRONTEND_VISIBLE>
DOCKER_CORS_ORIGINS=http://<IP_O_HOST_VISIBLE>:<PUERTO_FRONTEND_VISIBLE>

JWT_SECRET=<SECRETO_LARGO_MINIMO_32_CARACTERES>
JWT_EXPIRES_IN=2h
JWT_ISSUER=ubbike-api
JWT_AUDIENCE=ubbike-app
REFRESH_TOKEN_EXPIRES_DAYS=30
QR_DURATION_SECONDS=15

SEED_DEMO_DATA=true
SWAGGER_ENABLED=false
RATE_LIMIT_FACTOR=20

SMTP_HOST=
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=
SMTP_PASSWORD=
MAIL_FROM="UBBike <no-reply@ubbike.local>"

FIREBASE_CREDENTIALS_PATH=
```

Notas:

- Para evaluacion/demo se puede usar `SEED_DEMO_DATA=true`.
- Para produccion real usa `SEED_DEMO_DATA=false` y `RATE_LIMIT_FACTOR=1`.
- `PUBLIC_API_BASE_URL`, `PUBLIC_WS_BASE_URL`, `DOCKER_FRONTEND_URL` y `DOCKER_CORS_ORIGINS` deben usar la URL publica accesible desde navegador o dispositivo movil, no necesariamente la IP interna del contenedor.
- Si se usa Firebase, el JSON real debe quedar fuera de Git. Con Docker Compose puede montarse en `backend/secrets/firebase-admin.json` y referenciarse como `/app/secrets/firebase-admin.json`.

## Despliegue por SSH con Docker Compose

Entrar al servidor:

```bash
ssh -p <PUERTO_SSH> <USUARIO>@<IP_O_HOST_SSH>
```

Clonar la rama de Docker Compose:

```bash
git clone -b rama-dev-docker https://github.com/SebastianPinto2424/ubbike-taller.git ubbike
cd ubbike
```

Crear el `.env` de forma automatizada con el script incluido en el repositorio:

```bash
./preparar-env.sh <IP_O_HOST_VISIBLE> [PUERTO_BACKEND_VISIBLE] [PUERTO_FRONTEND_VISIBLE]
```

El script copia `.env.example` a `.env` y apunta las URLs publicas a la IP indicada. Sin argumentos deja los valores por defecto (`localhost`). Ademas habilita secretos opcionales que nunca se versionan en git:

- Si existe `backend/secrets/firebase-admin.json` (subido antes por `scp`), activa las notificaciones push.
- Si se entregan credenciales SMTP, activa el envio de correos:

```bash
SMTP_USER=<correo> SMTP_PASSWORD=<clave_de_aplicacion> ./preparar-env.sh <IP_O_HOST_VISIBLE>
```

Alternativa manual: `cp .env.example .env` y editar con `nano .env` las variables `PUBLIC_API_BASE_URL`, `PUBLIC_WS_BASE_URL`, `DOCKER_FRONTEND_URL`, `DOCKER_CORS_ORIGINS`, `POSTGRES_PASSWORD` y `JWT_SECRET` (guardar con `Ctrl + O`, `Enter`, salir con `Ctrl + X`).

Levantar el stack:

```bash
docker compose up -d --build
```

Verificar:

```bash
docker compose ps
docker compose logs -f backend
curl http://127.0.0.1:<PUERTO_BACKEND_EN_SERVIDOR>/salud
```

Probar desde un equipo cliente o dispositivo movil:

```text
http://<IP_O_HOST_VISIBLE>:<PUERTO_BACKEND_VISIBLE>/salud
http://<IP_O_HOST_VISIBLE>:<PUERTO_FRONTEND_VISIBLE>
```

## Levantar produccion con Docker Compose

Desde la raiz del proyecto:

```bash
docker compose up -d --build
```

Verificar contenedores:

```bash
docker compose ps
```

Ver logs del backend:

```bash
docker compose logs -f backend
```

Probar salud del backend:

```bash
curl http://127.0.0.1:<PUERTO_BACKEND_EN_SERVIDOR>/salud
```

Desde un equipo cliente o dispositivo movil con acceso a la red de despliegue:

```text
http://<IP_O_HOST_VISIBLE>:<PUERTO_BACKEND_VISIBLE>/salud
http://<IP_O_HOST_VISIBLE>:<PUERTO_FRONTEND_VISIBLE>
```

Si `/salud` no responde desde el dispositivo movil, la APK tampoco podra conectarse. En ese caso se deben revisar puertos publicados, firewall, red institucional o NAT.

## Actualizar una version desplegada

Con cambios nuevos en la rama:

```bash
git pull
docker compose up -d --build
docker compose ps
docker compose logs -f backend
```

Para reiniciar sin reconstruir imagenes:

```bash
docker compose restart
```

Para detener el stack sin borrar datos:

```bash
docker compose down
```

No usar `docker compose down -v` salvo que se requiera eliminar los volumenes de PostgreSQL y uploads.

## Compilar APK para probar contra el despliegue

Confirmar primero desde el dispositivo movil que el backend responde:

```text
http://<IP_O_HOST_VISIBLE>:<PUERTO_BACKEND_VISIBLE>/salud
```

Para prueba por HTTP en red local o institucional, compila APK debug:

```bash
cd mobile
flutter pub get
flutter build apk --debug --dart-define=API_BASE_URL=http://<IP_O_HOST_VISIBLE>:<PUERTO_BACKEND_VISIBLE>
```

APK generada:

```text
mobile/build/app/outputs/flutter-apk/app-debug.apk
```

Para una APK release se debe usar HTTPS:

```bash
cd mobile
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://<IP_O_HOST_VISIBLE>:<PUERTO_HTTPS_VISIBLE>
```

La variante debug permite HTTP para pruebas. La variante release debe apuntar a un origen HTTPS valido.

## Cuentas demo

Con `SEED_DEMO_DATA=true` se cargan cuentas de prueba:

| Rol | Cuenta |
| --- | --- |
| Usuario | `estudiante@alumnos.ubiobio.cl` |
| Guardia | `guardia@ubiobio.cl` |
| Administrador | `administrador@ubiobio.cl` |

Contrasena demo:

```text
UBBike2026*
```

## Validaciones antes de publicar cambios

Backend:

```bash
cd backend
npm run typecheck
npm test
```

Mobile:

```bash
cd mobile
flutter analyze
```

Docker Compose:

```bash
docker compose --env-file .env.example config --quiet
```

## Seguridad

- No subir `.env`, credenciales, certificados privados, APKs ni archivos reales de Firebase.
- `JWT_SECRET` debe ser unico y tener al menos 32 caracteres.
- PostgreSQL y Redis no deben exponerse publicamente si no es necesario.
- Usar `SEED_DEMO_DATA=false` y `RATE_LIMIT_FACTOR=1` en produccion real.
- Mantener respaldos de los volumenes Docker de PostgreSQL y uploads.

## Documentacion adicional

- `docs/desarrollo-y-api.md`
- `docs/modelo-relacional.md`
