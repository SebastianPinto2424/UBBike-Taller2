# Modelo Relacional UBBike

Este documento presenta el modelo relacional completo desarrollado para UBBike.
El repositorio `ubbike-taller` incluye este MR en código mediante el esquema de
Prisma y sus migraciones.

La fuente técnica del modelo se encuentra en `backend/prisma/schema.prisma`, con
sus migraciones en `backend/prisma/migrations`.


## Diagrama ER Completo

```mermaid
erDiagram
  USUARIOS ||--o{ BICICLETAS : registra
  USUARIOS ||--o{ MOVIMIENTOS : realiza
  USUARIOS ||--o{ MOVIMIENTOS : valida_como_guardia
  USUARIOS ||--o{ CODIGOS_QR_TEMPORALES : genera
  USUARIOS ||--o{ ASIGNACIONES_GUARDIAS : tiene_asignacion
  USUARIOS ||--o{ SOLICITUDES_GUARDIA : solicita
  USUARIOS ||--o{ SOLICITUDES_GUARDIA : atiende
  USUARIOS ||--o{ NOTIFICACIONES : recibe
  USUARIOS ||--o{ INCIDENCIAS : reporta
  USUARIOS ||--o{ AUDITORIA_EVENTOS : ejecuta

  BICICLETAS ||--o{ MOVIMIENTOS : genera
  BICICLETAS ||--o{ CODIGOS_QR_TEMPORALES : usa
  BICICLETAS ||--o{ INCIDENCIAS : asociada

  BICICLETEROS ||--o{ BICICLETAS : contiene_actualmente
  BICICLETEROS ||--o{ MOVIMIENTOS : registra
  BICICLETEROS ||--o{ CODIGOS_QR_TEMPORALES : destino
  BICICLETEROS ||--o{ ASIGNACIONES_GUARDIAS : asigna
  BICICLETEROS ||--o{ SOLICITUDES_GUARDIA : recibe
  BICICLETEROS ||--o{ INCIDENCIAS : contiene

  USUARIOS {
    uuid id PK
    varchar nombre
    varchar correo UK
    varchar rut UK
    enum rol
    varchar contrasena_hash
    boolean correo_verificado
    boolean registro_parcial
    boolean cuenta_activa
    integer version_sesion
    varchar token_verificacion_correo
    timestamptz token_verificacion_correo_expira_en
    varchar token_cambio_contrasena
    timestamptz token_cambio_contrasena_expira_en
    timestamptz creado_en
    timestamptz actualizado_en
  }

  BICICLETAS {
    uuid id PK
    uuid usuario_id FK
    uuid bicicletero_actual_id FK
    varchar descripcion
    varchar marca
    varchar modelo
    varchar color
    varchar aro
    varchar numero_serie
    text foto_url
    boolean activa
    boolean dentro_bicicletero
    timestamptz creado_en
    timestamptz actualizado_en
    timestamptz eliminado_en
  }

  BICICLETEROS {
    uuid id PK
    varchar nombre UK
    varchar ubicacion
    integer capacidad
    boolean activo
    timestamptz creado_en
    timestamptz actualizado_en
  }

  MOVIMIENTOS {
    uuid id PK
    uuid bicicleta_id FK
    uuid usuario_id FK
    uuid bicicletero_id FK
    uuid validado_por_guardia_id FK
    enum tipo
    enum estado
    varchar origen
    text motivo_denegacion
    text comentario_guardia
    timestamptz creado_en
  }

  CODIGOS_QR_TEMPORALES {
    uuid id PK
    varchar token UK
    uuid usuario_id FK
    uuid bicicleta_id FK
    uuid bicicletero_id FK
    enum tipo
    timestamptz expira_en
    boolean usado
    uuid escaneado_por_usuario_id
    timestamptz escaneado_en
    timestamptz creado_en
  }

  ASIGNACIONES_GUARDIAS {
    uuid id PK
    uuid guardia_id FK
    uuid bicicletero_id FK
    timestamptz inicia_en
    timestamptz termina_en
    boolean activa
    timestamptz creada_en
    timestamptz actualizada_en
  }

  SOLICITUDES_GUARDIA {
    uuid id PK
    uuid solicitada_por_usuario_id FK
    uuid bicicletero_id FK
    uuid guardia_asignado_id FK
    enum tipo
    enum estado
    text mensaje
    timestamptz notificada_guardia_en
    timestamptz ultima_notificacion_usuario_en
    integer notificaciones_guardia
    timestamptz acuse_recibo_en
    timestamptz resuelta_en
    timestamptz creada_en
    timestamptz actualizada_en
  }

  NOTIFICACIONES {
    uuid id PK
    uuid usuario_id FK
    varchar titulo
    text mensaje
    enum tipo
    boolean leida
    jsonb datos
    timestamptz creada_en
  }

  INCIDENCIAS {
    uuid id PK
    uuid usuario_id FK
    uuid bicicletero_id FK
    uuid bicicleta_id FK
    text descripcion
    enum estado
    timestamptz creada_en
    timestamptz actualizada_en
  }

  AUDITORIA_EVENTOS {
    uuid id PK
    uuid actor_usuario_id FK
    varchar accion
    varchar entidad
    varchar entidad_id
    varchar ip
    text user_agent
    jsonb datos
    timestamptz creado_en
  }
```

## Reglas De Negocio Principales

- Un usuario puede registrar muchas bicicletas.
- Una bicicleta pertenece a un único usuario.
- Solo una bicicleta por usuario deberia quedar marcada como activa.
- Las bicicletas se eliminan lógicamente con `eliminado_en`.
- Un bicicletero tiene capacidad, ubicacion y estado activo.
- Un guardia puede tener asignaciones a bicicleteros.
- Cada movimiento registra usuario, bicicleta, bicicletero, tipo, estado, origen
  y guardia que valida.
- Un movimiento puede ser confirmado o denegado.
- Si se deniega un ingreso o retiro, debe registrarse el motivo.
- Los códigos QR temporales pertenecen a un usuario y una bicicleta.
- El QR puede expirar visualmente para el usuario, pero debe marcarse como usado
  solo cuando se confirma o deniega el movimiento.
- Las solicitudes de guardia permiten pedir atención y dejar trazabilidad de
  aviso, respuesta, estado y resolución.
- Las notificaciones registran avisos relevantes para usuarios, guardias,
  administradores y central.
- Las incidencias permiten registrar problemas asociados a usuarios,
  bicicletas o bicicleteros.
- La auditoría conserva acciones importantes para revisiónes posteriores.
