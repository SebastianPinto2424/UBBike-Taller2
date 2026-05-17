# Desarrollo y API

## Estado Parcial Del Proyecto

El flujo disponible cubre autenticación, verificación de correo, roles base,
bicicleteros activos, gestión administrativa de usuarios y gestión de bicicletas.
El modelo relacional completo se encuentra definido en `backend/prisma/schema.prisma`
y aplicado mediante las migraciones de Prisma.

## Ejecutar Con Docker

Desde la raíz del proyecto:

```bash
docker compose up
```

Si se requiere reconstruir imágenes:

```bash
docker compose up --build
```

Accesos:

- Aplicación web: http://localhost:8082
- Backend health: http://localhost:3001/health
- Mailpit: http://localhost:8026

Para detener:

```bash
docker compose down
```

## Credenciales de prueba

Todas las cuentas usan:

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

## Lo que se puede hacer

1. Abrir http://localhost:8082.
2. Iniciar sesión con `estudiante@alumnos.ubiobio.cl`.
3. Entrar a `Bicicletas`.
4. Registrar una bicicleta.
5. Editar marca, modelo, color, aro o número de serie.
6. Marcar una bicicleta como activa.
7. Revisar `Perfil`.
8. Cerrar sesión.

Para probar registro:

1. Crear una cuenta desde la pantalla de registro.
2. Abrir Mailpit en http://localhost:8026.
3. Abrir el correo de verificación.
4. Usar el enlace de verificación.
5. Iniciar sesión con la cuenta creada.

Para probar la gestión administrativa de usuarios:

1. Iniciar sesión con `administrador@ubiobio.cl` y `UBBike2026*`.
2. Entrar a `Usuarios`.
3. Editar datos de una cuenta.
4. Cambiar el rol, estado de cuenta o verificación de correo.
5. Desactivar y volver a activar una cuenta de prueba.

## Endpoints Implementados

Autenticación:

```text
POST /autenticacion/registro
POST /autenticacion/login
GET  /autenticacion/perfil
GET  /autenticacion/verificar-correo
POST /autenticacion/verificar-correo
POST /autenticacion/solicitar-cambio-contrasena
POST /autenticacion/cambiar-contrasena
```

Bicicleteros:

```text
GET /bicicleteros
```

Usuarios:

```text
GET    /usuarios
PATCH  /usuarios/:id/permisos
```

Bicicletas:

```text
GET    /bicicletas
GET    /bicicletas/activa
POST   /bicicletas
PATCH  /bicicletas/:id
DELETE /bicicletas/:id
PATCH  /bicicletas/:id/activar
PATCH  /bicicletas/:id/desactivar
```

Health:

```text
GET /health
```
