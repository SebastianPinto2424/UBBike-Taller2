# UBBike

Proyecto UBBike. El sistema
incluye API REST con Node.js, Express, TypeScript, Prisma y PostgreSQL, junto
con una aplicación Flutter Web/Mobile para probar el estado parcial del MVP.

## Estado Parcial Desarrollado

- Registro de usuarios con correo institucional.
- Validación de RUT, correo y contraseña segura.
- Verificación de correo mediante Mailpit.
- Inicio de sesión con JWT.
- Recuperación y cambio de contraseña.
- Roles base: estudiante, funcionario, guardia, admin central y administrador.
- Gestión administrativa de usuarios y permisos para el rol administrador.
- Registro, edición, activación, desactivación y eliminación lógica de
  bicicletas.
- Listado de bicicleteros activos.
- Pantallas Flutter de login, registro, inicio, bicicletas y perfil.
- Estructura Flutter multiplataforma con carpetas `android`, `ios` y `web`.
- Datos de prueba cargados automáticamente.
- Modelo relacional completo implementado en Prisma y documentado en
  `docs/modelo-relacional.md`.

## Ejecutar Con Docker

Clonar el repositorio, entrar a la carpeta y levantar los servicios:

```bash
git clone https://github.com/SebastianPinto2424/ubbike-taller.git
cd ubbike-taller
docker compose up
```

Si Docker necesita reconstruir las imágenes:

```bash
docker compose up --build
```

Accesos locales:

- Aplicación web: http://localhost:8082
- Backend health: http://localhost:3001/health
- Mailpit: http://localhost:8026
- PostgreSQL: `127.0.0.1:5433`

Para detener el sistema:

```bash
docker compose down
```

Para reiniciar desde cero eliminando la base local:

```bash
docker compose down -v
docker compose up --build
```

## Credenciales De Prueba

Todas las cuentas demo usan:

```text
UBBike2026*
```

| Rol | Correo |
| --- | --- |
| Estudiante | `estudiante@alumnos.ubiobio.cl` |
| Funcionario | `funcionario@ubiobio.cl` |
| Guardia | `guardia@ubiobio.cl` |
| Administrador | `administrador@ubiobio.cl` |

## Para probar

1. Abrir http://localhost:8082.
2. Iniciar sesión con `estudiante@alumnos.ubiobio.cl` y `UBBike2026*`.
3. Entrar a `Bicicletas`.
4. Registrar una bicicleta.
5. Editar sus datos: marca, modelo, color, aro o número de serie.
6. Marcarla como activa.
7. Revisar `Perfil` y cerrar sesión.

Para probar registro:

1. Crear una cuenta nueva desde la pantalla de registro.
2. Abrir Mailpit en http://localhost:8026.
3. Abrir el correo de verificación.
4. Usar el enlace recibido.
5. Iniciar sesión con la cuenta creada.

Para probar gestión administrativa de usuarios:

1. Iniciar sesión con `administrador@ubiobio.cl` y `UBBike2026*`.
2. Entrar a `Usuarios`.
3. Editar datos de una cuenta.
4. Cambiar el rol, estado de cuenta o verificación de correo.
5. Desactivar y volver a activar una cuenta de prueba.

