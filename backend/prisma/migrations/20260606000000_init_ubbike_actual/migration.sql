CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA IF NOT EXISTS "public";

CREATE TYPE "usuarios_rol_enum" AS ENUM ('ESTUDIANTE', 'FUNCIONARIO', 'GUARDIA', 'ADMIN_CENTRAL', 'ADMINISTRADOR');

CREATE TYPE "movimientos_tipo_enum" AS ENUM ('INGRESO', 'RETIRO');

CREATE TYPE "codigos_qr_temporales_tipo_enum" AS ENUM ('INGRESO', 'RETIRO');

CREATE TYPE "movimientos_origen_enum" AS ENUM ('QR', 'MANUAL');

CREATE TYPE "movimientos_estado_enum" AS ENUM ('CONFIRMADO', 'DENEGADO');

CREATE TYPE "solicitudes_guardia_tipo_enum" AS ENUM ('GUARDIA_AUSENTE', 'REQUIERE_SERVICIO');

CREATE TYPE "solicitudes_guardia_estado_enum" AS ENUM ('PENDIENTE', 'NOTIFICADA', 'EN_CAMINO', 'RESUELTA', 'CANCELADA');

CREATE TYPE "incidencias_estado_enum" AS ENUM ('PENDIENTE', 'EN_REVISION', 'RESUELTA', 'DESCARTADA');

CREATE TYPE "incidencias_tipo_enum" AS ENUM ('PROBLEMA_QR', 'DANO_BICICLETA', 'DANO_INFRAESTRUCTURA', 'PROBLEMA_MOVIMIENTO', 'USUARIO_DATOS', 'OTRO');

CREATE TYPE "notificaciones_tipo_enum" AS ENUM ('SISTEMA', 'CUENTA', 'SEGURIDAD', 'SOLICITUD_GUARDIA', 'MOVIMIENTO', 'INCIDENCIA');

CREATE TABLE "usuarios" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "nombre" VARCHAR(120) NOT NULL,
    "correo" VARCHAR(160) NOT NULL,
    "rut" VARCHAR(20),
    "rol" "usuarios_rol_enum" NOT NULL DEFAULT 'ESTUDIANTE',
    "contrasena_hash" VARCHAR(255) NOT NULL,
    "correo_verificado" BOOLEAN NOT NULL DEFAULT false,
    "registro_parcial" BOOLEAN NOT NULL DEFAULT false,
    "cuenta_activa" BOOLEAN NOT NULL DEFAULT true,
    "version_sesion" INTEGER NOT NULL DEFAULT 0,
    "token_verificacion_correo" VARCHAR(120),
    "token_verificacion_correo_expira_en" TIMESTAMPTZ(6),
    "token_cambio_contrasena" VARCHAR(120),
    "token_cambio_contrasena_expira_en" TIMESTAMPTZ(6),
    "creado_en" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizado_en" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "bicicletas" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "usuario_id" UUID NOT NULL,
    "descripcion" VARCHAR(255) NOT NULL,
    "marca" VARCHAR(80),
    "modelo" VARCHAR(80),
    "color" VARCHAR(60),
    "aro" VARCHAR(30),
    "numero_serie" VARCHAR(120),
    "foto_url" TEXT,
    "foto_nombre_archivo" VARCHAR(160),
    "foto_mime_type" VARCHAR(80),
    "foto_tamano_bytes" INTEGER,
    "foto_actualizada_en" TIMESTAMPTZ(6),
    "activa" BOOLEAN NOT NULL DEFAULT false,
    "dentro_bicicletero" BOOLEAN NOT NULL DEFAULT false,
    "bicicletero_actual_id" UUID,
    "creado_en" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizado_en" TIMESTAMPTZ(6) NOT NULL,
    "eliminado_en" TIMESTAMPTZ(6),

    CONSTRAINT "bicicletas_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "bicicleteros" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "nombre" VARCHAR(120) NOT NULL,
    "ubicacion" VARCHAR(255) NOT NULL,
    "capacidad" INTEGER NOT NULL DEFAULT 80,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "creado_en" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizado_en" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "bicicleteros_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "asignaciones_guardias" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "guardia_id" UUID NOT NULL,
    "bicicletero_id" UUID NOT NULL,
    "inicia_en" TIMESTAMPTZ(6) NOT NULL,
    "termina_en" TIMESTAMPTZ(6),
    "activa" BOOLEAN NOT NULL DEFAULT true,
    "creada_en" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizada_en" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "asignaciones_guardias_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "solicitudes_guardia" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "solicitada_por_usuario_id" UUID NOT NULL,
    "bicicletero_id" UUID NOT NULL,
    "guardia_asignado_id" UUID,
    "tipo" "solicitudes_guardia_tipo_enum" NOT NULL,
    "estado" "solicitudes_guardia_estado_enum" NOT NULL DEFAULT 'PENDIENTE',
    "mensaje" TEXT,
    "notificada_guardia_en" TIMESTAMPTZ(6),
    "ultima_notificacion_usuario_en" TIMESTAMPTZ(6),
    "notificaciones_guardia" INTEGER NOT NULL DEFAULT 0,
    "respondida_por_guardia_en" TIMESTAMPTZ(6),
    "en_camino_en" TIMESTAMPTZ(6),
    "resuelta_en" TIMESTAMPTZ(6),
    "creada_en" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizada_en" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "solicitudes_guardia_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "movimientos" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "bicicleta_id" UUID NOT NULL,
    "usuario_id" UUID NOT NULL,
    "bicicletero_id" UUID NOT NULL,
    "validado_por_guardia_id" UUID NOT NULL,
    "tipo" "movimientos_tipo_enum" NOT NULL,
    "estado" "movimientos_estado_enum" NOT NULL DEFAULT 'CONFIRMADO',
    "motivo_denegacion" TEXT,
    "comentario_guardia" TEXT,
    "origen" "movimientos_origen_enum" NOT NULL DEFAULT 'QR',
    "creado_en" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "movimientos_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "codigos_qr_temporales" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "token" VARCHAR(160) NOT NULL,
    "usuario_id" UUID NOT NULL,
    "bicicleta_id" UUID NOT NULL,
    "bicicletero_id" UUID,
    "tipo" "codigos_qr_temporales_tipo_enum" NOT NULL,
    "expira_en" TIMESTAMPTZ(6) NOT NULL,
    "usado" BOOLEAN NOT NULL DEFAULT false,
    "escaneado_por_guardia_id" UUID,
    "escaneado_en" TIMESTAMPTZ(6),
    "creado_en" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "codigos_qr_temporales_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "notificaciones" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "usuario_id" UUID NOT NULL,
    "titulo" VARCHAR(120) NOT NULL,
    "mensaje" TEXT NOT NULL,
    "tipo" "notificaciones_tipo_enum" NOT NULL DEFAULT 'SISTEMA',
    "leida" BOOLEAN NOT NULL DEFAULT false,
    "datos" JSONB,
    "creada_en" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notificaciones_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "incidencias" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "reportada_por_usuario_id" UUID NOT NULL,
    "bicicletero_id" UUID NOT NULL,
    "bicicleta_id" UUID,
    "gestionada_por_usuario_id" UUID,
    "tipo" "incidencias_tipo_enum" NOT NULL DEFAULT 'OTRO',
    "descripcion" TEXT NOT NULL,
    "estado" "incidencias_estado_enum" NOT NULL DEFAULT 'PENDIENTE',
    "respuesta" TEXT,
    "resuelta_en" TIMESTAMPTZ(6),
    "creada_en" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizada_en" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "incidencias_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "auditoria_eventos" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "actor_usuario_id" UUID,
    "accion" VARCHAR(120) NOT NULL,
    "entidad" VARCHAR(120) NOT NULL,
    "entidad_id" VARCHAR(120),
    "ip" VARCHAR(80),
    "user_agent" TEXT,
    "datos" JSONB,
    "creado_en" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "auditoria_eventos_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "usuarios_correo_key" ON "usuarios"("correo");

CREATE UNIQUE INDEX "usuarios_rut_key" ON "usuarios"("rut");

CREATE INDEX "idx_bicicletas_usuario" ON "bicicletas"("usuario_id");

CREATE INDEX "idx_bicicletas_bicicletero_actual" ON "bicicletas"("bicicletero_actual_id");

CREATE UNIQUE INDEX "bicicleteros_nombre_key" ON "bicicleteros"("nombre");

CREATE INDEX "idx_asignaciones_guardia_activa" ON "asignaciones_guardias"("guardia_id", "bicicletero_id", "activa");

CREATE INDEX "idx_solicitudes_guardia_estado" ON "solicitudes_guardia"("estado", "creada_en");

CREATE INDEX "idx_solicitudes_guardia_guardia" ON "solicitudes_guardia"("guardia_asignado_id");

CREATE INDEX "idx_movimientos_usuario_creado" ON "movimientos"("usuario_id", "creado_en");

CREATE INDEX "idx_movimientos_guardia_creado" ON "movimientos"("validado_por_guardia_id", "creado_en");

CREATE INDEX "idx_movimientos_bicicletero_creado" ON "movimientos"("bicicletero_id", "creado_en");

CREATE UNIQUE INDEX "codigos_qr_temporales_token_key" ON "codigos_qr_temporales"("token");

CREATE INDEX "idx_qr_token" ON "codigos_qr_temporales"("token");

CREATE INDEX "idx_qr_escaneo_guardia" ON "codigos_qr_temporales"("escaneado_por_guardia_id", "escaneado_en");

CREATE INDEX "idx_notificaciones_usuario_leida" ON "notificaciones"("usuario_id", "leida", "creada_en");

CREATE INDEX "idx_incidencias_estado_creada" ON "incidencias"("estado", "creada_en");

CREATE INDEX "idx_incidencias_bicicletero_estado" ON "incidencias"("bicicletero_id", "estado");

CREATE INDEX "idx_incidencias_reportante_creada" ON "incidencias"("reportada_por_usuario_id", "creada_en");

CREATE INDEX "idx_auditoria_actor_creado" ON "auditoria_eventos"("actor_usuario_id", "creado_en");

CREATE INDEX "idx_auditoria_entidad_creado" ON "auditoria_eventos"("entidad", "entidad_id", "creado_en");

ALTER TABLE "bicicletas" ADD CONSTRAINT "bicicletas_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "bicicletas" ADD CONSTRAINT "bicicletas_bicicletero_actual_id_fkey" FOREIGN KEY ("bicicletero_actual_id") REFERENCES "bicicleteros"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "asignaciones_guardias" ADD CONSTRAINT "asignaciones_guardias_guardia_id_fkey" FOREIGN KEY ("guardia_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "asignaciones_guardias" ADD CONSTRAINT "asignaciones_guardias_bicicletero_id_fkey" FOREIGN KEY ("bicicletero_id") REFERENCES "bicicleteros"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "solicitudes_guardia" ADD CONSTRAINT "solicitudes_guardia_solicitada_por_usuario_id_fkey" FOREIGN KEY ("solicitada_por_usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "solicitudes_guardia" ADD CONSTRAINT "solicitudes_guardia_bicicletero_id_fkey" FOREIGN KEY ("bicicletero_id") REFERENCES "bicicleteros"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "solicitudes_guardia" ADD CONSTRAINT "solicitudes_guardia_guardia_asignado_id_fkey" FOREIGN KEY ("guardia_asignado_id") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "movimientos" ADD CONSTRAINT "movimientos_bicicleta_id_fkey" FOREIGN KEY ("bicicleta_id") REFERENCES "bicicletas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "movimientos" ADD CONSTRAINT "movimientos_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "movimientos" ADD CONSTRAINT "movimientos_bicicletero_id_fkey" FOREIGN KEY ("bicicletero_id") REFERENCES "bicicleteros"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "movimientos" ADD CONSTRAINT "movimientos_validado_por_guardia_id_fkey" FOREIGN KEY ("validado_por_guardia_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "codigos_qr_temporales" ADD CONSTRAINT "codigos_qr_temporales_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "codigos_qr_temporales" ADD CONSTRAINT "codigos_qr_temporales_bicicleta_id_fkey" FOREIGN KEY ("bicicleta_id") REFERENCES "bicicletas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "codigos_qr_temporales" ADD CONSTRAINT "codigos_qr_temporales_bicicletero_id_fkey" FOREIGN KEY ("bicicletero_id") REFERENCES "bicicleteros"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "codigos_qr_temporales" ADD CONSTRAINT "codigos_qr_temporales_escaneado_por_guardia_id_fkey" FOREIGN KEY ("escaneado_por_guardia_id") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "notificaciones" ADD CONSTRAINT "notificaciones_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "incidencias" ADD CONSTRAINT "incidencias_reportada_por_usuario_id_fkey" FOREIGN KEY ("reportada_por_usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "incidencias" ADD CONSTRAINT "incidencias_gestionada_por_usuario_id_fkey" FOREIGN KEY ("gestionada_por_usuario_id") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "incidencias" ADD CONSTRAINT "incidencias_bicicletero_id_fkey" FOREIGN KEY ("bicicletero_id") REFERENCES "bicicleteros"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "incidencias" ADD CONSTRAINT "incidencias_bicicleta_id_fkey" FOREIGN KEY ("bicicleta_id") REFERENCES "bicicletas"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "auditoria_eventos" ADD CONSTRAINT "auditoria_eventos_actor_usuario_id_fkey" FOREIGN KEY ("actor_usuario_id") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;

