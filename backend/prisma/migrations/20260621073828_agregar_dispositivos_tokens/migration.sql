-- DropForeignKey
ALTER TABLE "asignaciones_guardias" DROP CONSTRAINT "asignaciones_guardias_bicicletero_id_fkey";

-- DropForeignKey
ALTER TABLE "asignaciones_guardias" DROP CONSTRAINT "asignaciones_guardias_guardia_id_fkey";

-- DropForeignKey
ALTER TABLE "auditoria_eventos" DROP CONSTRAINT "auditoria_eventos_actor_usuario_id_fkey";

-- DropForeignKey
ALTER TABLE "bicicletas" DROP CONSTRAINT "bicicletas_bicicletero_actual_id_fkey";

-- DropForeignKey
ALTER TABLE "bicicletas" DROP CONSTRAINT "bicicletas_usuario_id_fkey";

-- DropForeignKey
ALTER TABLE "codigos_qr_temporales" DROP CONSTRAINT "codigos_qr_temporales_bicicleta_id_fkey";

-- DropForeignKey
ALTER TABLE "codigos_qr_temporales" DROP CONSTRAINT "codigos_qr_temporales_bicicletero_id_fkey";

-- DropForeignKey
ALTER TABLE "codigos_qr_temporales" DROP CONSTRAINT "codigos_qr_temporales_usuario_id_fkey";

-- DropForeignKey
ALTER TABLE "incidencias" DROP CONSTRAINT "incidencias_bicicleta_id_fkey";

-- DropForeignKey
ALTER TABLE "incidencias" DROP CONSTRAINT "incidencias_bicicletero_id_fkey";

-- DropForeignKey
ALTER TABLE "incidencias" DROP CONSTRAINT "incidencias_usuario_id_fkey";

-- DropForeignKey
ALTER TABLE "movimientos" DROP CONSTRAINT "movimientos_bicicleta_id_fkey";

-- DropForeignKey
ALTER TABLE "movimientos" DROP CONSTRAINT "movimientos_bicicletero_id_fkey";

-- DropForeignKey
ALTER TABLE "movimientos" DROP CONSTRAINT "movimientos_usuario_id_fkey";

-- DropForeignKey
ALTER TABLE "movimientos" DROP CONSTRAINT "movimientos_validado_por_guardia_id_fkey";

-- DropForeignKey
ALTER TABLE "notificaciones" DROP CONSTRAINT "notificaciones_usuario_id_fkey";

-- DropForeignKey
ALTER TABLE "solicitudes_guardia" DROP CONSTRAINT "solicitudes_guardia_bicicletero_id_fkey";

-- DropForeignKey
ALTER TABLE "solicitudes_guardia" DROP CONSTRAINT "solicitudes_guardia_guardia_asignado_id_fkey";

-- DropForeignKey
ALTER TABLE "solicitudes_guardia" DROP CONSTRAINT "solicitudes_guardia_solicitada_por_usuario_id_fkey";

-- DropIndex
DROP INDEX "idx_usuarios_eliminado_en";

-- AlterTable
ALTER TABLE "asignaciones_guardias" ALTER COLUMN "actualizada_en" DROP DEFAULT;

-- AlterTable
ALTER TABLE "bicicletas" ALTER COLUMN "actualizado_en" DROP DEFAULT;

-- AlterTable
ALTER TABLE "bicicleteros" ALTER COLUMN "actualizado_en" DROP DEFAULT;

-- AlterTable
ALTER TABLE "incidencias" ALTER COLUMN "actualizada_en" DROP DEFAULT;

-- AlterTable
ALTER TABLE "solicitudes_guardia" ALTER COLUMN "actualizada_en" DROP DEFAULT;

-- AlterTable
ALTER TABLE "usuarios" ALTER COLUMN "actualizado_en" DROP DEFAULT;

-- CreateTable
CREATE TABLE "dispositivos_tokens" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "usuario_id" UUID NOT NULL,
    "token" VARCHAR(255) NOT NULL,
    "plataforma" VARCHAR(20) NOT NULL DEFAULT 'android',
    "creado_en" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizado_en" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "dispositivos_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "dispositivos_tokens_token_key" ON "dispositivos_tokens"("token");

-- CreateIndex
CREATE INDEX "idx_dispositivos_usuario" ON "dispositivos_tokens"("usuario_id");

-- AddForeignKey
ALTER TABLE "bicicletas" ADD CONSTRAINT "bicicletas_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bicicletas" ADD CONSTRAINT "bicicletas_bicicletero_actual_id_fkey" FOREIGN KEY ("bicicletero_actual_id") REFERENCES "bicicleteros"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "asignaciones_guardias" ADD CONSTRAINT "asignaciones_guardias_guardia_id_fkey" FOREIGN KEY ("guardia_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "asignaciones_guardias" ADD CONSTRAINT "asignaciones_guardias_bicicletero_id_fkey" FOREIGN KEY ("bicicletero_id") REFERENCES "bicicleteros"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "solicitudes_guardia" ADD CONSTRAINT "solicitudes_guardia_solicitada_por_usuario_id_fkey" FOREIGN KEY ("solicitada_por_usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "solicitudes_guardia" ADD CONSTRAINT "solicitudes_guardia_bicicletero_id_fkey" FOREIGN KEY ("bicicletero_id") REFERENCES "bicicleteros"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "solicitudes_guardia" ADD CONSTRAINT "solicitudes_guardia_guardia_asignado_id_fkey" FOREIGN KEY ("guardia_asignado_id") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movimientos" ADD CONSTRAINT "movimientos_bicicleta_id_fkey" FOREIGN KEY ("bicicleta_id") REFERENCES "bicicletas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movimientos" ADD CONSTRAINT "movimientos_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movimientos" ADD CONSTRAINT "movimientos_bicicletero_id_fkey" FOREIGN KEY ("bicicletero_id") REFERENCES "bicicleteros"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movimientos" ADD CONSTRAINT "movimientos_validado_por_guardia_id_fkey" FOREIGN KEY ("validado_por_guardia_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "codigos_qr_temporales" ADD CONSTRAINT "codigos_qr_temporales_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "codigos_qr_temporales" ADD CONSTRAINT "codigos_qr_temporales_bicicleta_id_fkey" FOREIGN KEY ("bicicleta_id") REFERENCES "bicicletas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "codigos_qr_temporales" ADD CONSTRAINT "codigos_qr_temporales_bicicletero_id_fkey" FOREIGN KEY ("bicicletero_id") REFERENCES "bicicleteros"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notificaciones" ADD CONSTRAINT "notificaciones_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "dispositivos_tokens" ADD CONSTRAINT "dispositivos_tokens_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "incidencias" ADD CONSTRAINT "incidencias_reportada_por_usuario_id_fkey" FOREIGN KEY ("reportada_por_usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "incidencias" ADD CONSTRAINT "incidencias_bicicletero_id_fkey" FOREIGN KEY ("bicicletero_id") REFERENCES "bicicleteros"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "incidencias" ADD CONSTRAINT "incidencias_bicicleta_id_fkey" FOREIGN KEY ("bicicleta_id") REFERENCES "bicicletas"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "auditoria_eventos" ADD CONSTRAINT "auditoria_eventos_actor_usuario_id_fkey" FOREIGN KEY ("actor_usuario_id") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;
