ALTER TYPE "movimientos_tipo_enum" RENAME VALUE 'SALIDA' TO 'RETIRO';
ALTER TYPE "codigos_qr_temporales_tipo_enum" RENAME VALUE 'SALIDA' TO 'RETIRO';

CREATE TYPE "movimientos_origen_enum" AS ENUM ('QR', 'MANUAL');

ALTER TABLE "movimientos"
  ALTER COLUMN "origen" DROP DEFAULT;

ALTER TABLE "movimientos"
  ALTER COLUMN "origen" TYPE "movimientos_origen_enum"
  USING "origen"::"movimientos_origen_enum";

ALTER TABLE "movimientos"
  ALTER COLUMN "origen" SET DEFAULT 'QR';

ALTER TABLE "bicicletas"
  ADD COLUMN "foto_nombre_archivo" VARCHAR(160),
  ADD COLUMN "foto_mime_type" VARCHAR(80),
  ADD COLUMN "foto_tamano_bytes" INTEGER,
  ADD COLUMN "foto_actualizada_en" TIMESTAMPTZ(6);

DROP INDEX IF EXISTS "idx_qr_escaneo_usuario";

ALTER TABLE "codigos_qr_temporales"
  RENAME COLUMN "escaneado_por_usuario_id" TO "escaneado_por_guardia_id";

ALTER TABLE "codigos_qr_temporales"
  ADD CONSTRAINT "codigos_qr_temporales_escaneado_por_guardia_id_fkey"
  FOREIGN KEY ("escaneado_por_guardia_id") REFERENCES "usuarios"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;

CREATE INDEX "idx_qr_escaneo_guardia"
  ON "codigos_qr_temporales"("escaneado_por_guardia_id", "escaneado_en");

ALTER TABLE "solicitudes_guardia"
  RENAME COLUMN "acuse_recibo_en" TO "respondida_por_guardia_en";

ALTER TABLE "solicitudes_guardia"
  ADD COLUMN "en_camino_en" TIMESTAMPTZ(6);

UPDATE "solicitudes_guardia"
SET "en_camino_en" = "respondida_por_guardia_en"
WHERE "estado"::TEXT IN ('VISTA', 'EN_CAMINO')
  AND "respondida_por_guardia_en" IS NOT NULL;

ALTER TYPE "solicitudes_guardia_estado_enum" RENAME TO "solicitudes_guardia_estado_enum_old";
CREATE TYPE "solicitudes_guardia_estado_enum" AS ENUM (
  'PENDIENTE',
  'NOTIFICADA',
  'EN_CAMINO',
  'RESUELTA',
  'CANCELADA'
);

ALTER TABLE "solicitudes_guardia"
  ALTER COLUMN "estado" DROP DEFAULT;

ALTER TABLE "solicitudes_guardia"
  ALTER COLUMN "estado" TYPE "solicitudes_guardia_estado_enum"
  USING (
    CASE
      WHEN "estado"::TEXT = 'VISTA' THEN 'EN_CAMINO'
      ELSE "estado"::TEXT
    END
  )::"solicitudes_guardia_estado_enum";

ALTER TABLE "solicitudes_guardia"
  ALTER COLUMN "estado" SET DEFAULT 'PENDIENTE';

DROP TYPE "solicitudes_guardia_estado_enum_old";

CREATE UNIQUE INDEX IF NOT EXISTS "idx_bicicletas_usuario_unica_activa"
  ON "bicicletas"("usuario_id")
  WHERE "activa" = TRUE AND "eliminado_en" IS NULL;
