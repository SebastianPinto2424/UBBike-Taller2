-- Activa el modulo de incidencias con clasificacion, gestion y notificaciones.

CREATE TYPE "incidencias_tipo_enum" AS ENUM (
  'PROBLEMA_QR',
  'DANO_BICICLETA',
  'DANO_INFRAESTRUCTURA',
  'PROBLEMA_MOVIMIENTO',
  'USUARIO_DATOS',
  'OTRO'
);

ALTER TYPE "notificaciones_tipo_enum" ADD VALUE IF NOT EXISTS 'INCIDENCIA';

ALTER TABLE "incidencias"
  RENAME COLUMN "usuario_id" TO "reportada_por_usuario_id";

ALTER TABLE "incidencias"
  ADD COLUMN "gestionada_por_usuario_id" UUID,
  ADD COLUMN "tipo" "incidencias_tipo_enum" NOT NULL DEFAULT 'OTRO',
  ADD COLUMN "respuesta" TEXT,
  ADD COLUMN "resuelta_en" TIMESTAMPTZ(6);

ALTER TABLE "incidencias"
  ADD CONSTRAINT "incidencias_gestionada_por_usuario_id_fkey"
  FOREIGN KEY ("gestionada_por_usuario_id") REFERENCES "usuarios"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;

CREATE INDEX "idx_incidencias_estado_creada"
  ON "incidencias"("estado", "creada_en");

CREATE INDEX "idx_incidencias_bicicletero_estado"
  ON "incidencias"("bicicletero_id", "estado");

CREATE INDEX "idx_incidencias_reportante_creada"
  ON "incidencias"("reportada_por_usuario_id", "creada_en");
