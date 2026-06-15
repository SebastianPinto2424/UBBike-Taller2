ALTER TABLE IF EXISTS solicitudes_guardia
  ADD COLUMN IF NOT EXISTS ultima_notificacion_usuario_en timestamp with time zone,
  ADD COLUMN IF NOT EXISTS notificaciones_guardia integer NOT NULL DEFAULT 0;

UPDATE solicitudes_guardia
SET
  notificaciones_guardia = 1,
  ultima_notificacion_usuario_en = notificada_guardia_en
WHERE notificada_guardia_en IS NOT NULL
  AND notificaciones_guardia = 0;
