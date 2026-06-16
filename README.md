# UBBike

Aplicación web/mobile y API REST para gestionar el registro de bicicletas, el ingreso y retiro desde bicicleteros, y la trazabilidad operativa de los accesos en la Universidad del Bío-Bío.

## Estructura del proyecto

- `backend/`: API REST con Node.js, Express, Prisma, PostgreSQL y Redis.
- `mobile/`: aplicación Flutter Web/Mobile con vistas por rol.
- `docs/`: documentación técnica, modelo relacional y notas de producción.

## Requisitos

- Docker Desktop y mantenerlo abierto durante la ejecución local.
- Git.
- Navegador web para probar la aplicación local.
- Flutter y Node.js solo si se desea ejecutar sin Docker.

## Entrega Docker Compose

Esta sección contiene el procedimiento específico para la entrega de integración con Docker Compose. El archivo `docker-compose.yml` se encuentra en la raíz del repositorio y levanta todos los servicios necesarios del proyecto.

### Requisitos para ejecutar

- Docker Desktop o Docker Engine con Docker Compose disponible.
- Git.
- Navegador web para acceder a la aplicación.
- Archivo `.env` si se desean personalizar puertos, secretos o SMTP real para Nodemailer.

### Procedimiento desde cero

Clonar el repositorio, entrar a la raíz del proyecto y levantar los servicios:

```bash
git clone https://github.com/SebastianPinto2424/ubbike.git
cd ubbike
docker compose up
```

Si el repositorio ya fue clonado previamente, entrar a la carpeta del proyecto, actualizar la rama principal y levantar los servicios:

```bash
git switch main
git pull
docker compose up
```

### Verificación de ejecución

Cuando los contenedores terminen de iniciar, verificar los siguientes accesos:

- Aplicación web: [http://localhost:8082](http://localhost:8082)
- Health check backend: [http://localhost:3001/health](http://localhost:3001/health)
- Correos: se envían por el SMTP configurado en `.env`; si no hay SMTP, se registran en consola.
- PostgreSQL local: `127.0.0.1:5433`

Para consultar el estado de los contenedores:

```bash
docker compose ps
```

Para detener la ejecución:

```bash
docker compose down
```

### Servicios definidos en Docker Compose

| Contenedor | Servicio | Puerto local | Función |
| --- | --- | --- | --- |
| `ubbike_taller_db` | PostgreSQL | `5433` | Almacena usuarios, bicicletas, bicicleteros, movimientos, solicitudes y notificaciones. |
| `ubbike_taller_redis` | Redis | `6380` | Mantiene contadores temporales para limitar intentos de acceso y proteger acciones sensibles. |
| `ubbike_taller_backend` | Backend API | `3001` | Expone la API REST, aplica reglas de negocio, seguridad, validaciones y migraciones. |
| `ubbike_taller_frontend` | Frontend Flutter Web | `8082` | Sirve la aplicación web de UBBike mediante Nginx. |

## Configuración opcional

Si desea personalizar puertos, contraseñas o secretos para Docker, edite el archivo `.env` de la raíz del proyecto.

Luego reemplace, como mínimo:

- `.env`: `POSTGRES_PASSWORD` por una clave segura.
- `.env`: `JWT_SECRET` por un secreto largo de 32 o más caracteres.

El archivo `.env` está ignorado por Git y no debe subirse al repositorio. El backend, Prisma y Docker Compose leen ese mismo archivo de la raíz.

## Despliegue local con Docker

Desde la carpeta principal del proyecto, si desea reconstruir y dejar los servicios en segundo plano, ejecute:

```bash
docker compose up -d --build
```

Para el servidor de produccion, copie `.env.ubb-prod.example` a `.env`, complete los datos reales y use el compose especifico:

```bash
docker compose -f docker-compose.ubb-prod.yml up -d --build
```

## Prueba con la app móvil nativa

Los contenedores de Docker exponen el backend en el puerto `3001`. Para conectar la app Flutter en un emulador o dispositivo físico:

```bash
# Emulador Android (10.0.2.2 apunta al localhost de la máquina anfitriona)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001

# Dispositivo físico (reemplazar con la IP local de la máquina)
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:3001
```

## Comandos útiles

Ejecutar o aplicar cambios:

```bash
docker compose up -d --build
```

Reconstrucción limpia sin caché:

```bash
docker compose build --no-cache
docker compose up -d
```

Detener conservando datos:

```bash
docker compose down
```

Reiniciar desde cero eliminando volúmenes:

```bash
docker compose down -v
docker compose up -d --build
```

Consultar estado:

```bash
docker compose ps
```

Consultar logs:

```bash
docker compose logs -f backend
docker compose logs -f frontend
```

### Base de datos existente y Prisma

Si se migra una base ya creada antes de Prisma, no elimine el volumen para "arreglar" el error `P3005`.
Primero aplique el SQL idempotente y luego registre la migración inicial como aplicada:

```powershell
docker compose stop backend
Get-Content -Raw backend\prisma\migrations\20260515123000_init\migration.sql | docker compose exec -T db psql -v ON_ERROR_STOP=1 -U ubbike -d ubbike
docker compose run --rm --no-deps backend npx prisma migrate resolve --applied 20260515123000_init
docker compose up -d
```

Use `docker compose down -v` solo cuando quiera borrar completamente los datos locales.

## Seguridad local

El proyecto queda preparado con una configuración segura base:

- Backend en `NODE_ENV=production`.
- Migraciones versionadas con Prisma Migrate.
- Backend ejecutado como usuario no root.
- Contenedores con `read_only`, `tmpfs`, `cap_drop` y `no-new-privileges`.
- Puertos publicados solo en `127.0.0.1` en entorno local.
- Redis para rate limiting distribuido.
- Nginx con headers de seguridad y CSP para Flutter Web.
- Validación estricta de correo institucional y contraseñas.
- Tokens de verificación de correo con expiración.
- QR temporal de corta duración.
- Validación de QR restringida al bicicletero activo del guardia.

## Credenciales demo

En local, `SEED_DEMO_DATA=true` crea usuarios de prueba. Todas las cuentas utilizan:

```text
UBBike2026*
```

| Rol | Correo |
| --- | --- |
| Estudiante | `estudiante@alumnos.ubiobio.cl` |
| Funcionario | `funcionario@ubiobio.cl` |
| Guardia | `guardia@ubiobio.cl` |
| Admin central | `admin.central@ubiobio.cl` |
| Administrador | `administrador@ubiobio.cl` |

En producción, `SEED_DEMO_DATA=false`.

## Documentación adicional

La documentación técnica adicional se encuentra en:

- `docs/desarrollo-y-api.md`: flujo funcional, endpoints principales, arranque sin Docker y validaciones.
- `docs/modelo-relacional.md`: modelo relacional del proyecto.
