ALTER TABLE IF EXISTS codigos_qr_temporales
  ADD COLUMN IF NOT EXISTS escaneado_por_usuario_id uuid,
  ADD COLUMN IF NOT EXISTS escaneado_en timestamp with time zone;

CREATE INDEX IF NOT EXISTS idx_qr_escaneo_usuario
  ON codigos_qr_temporales(escaneado_por_usuario_id, escaneado_en);
