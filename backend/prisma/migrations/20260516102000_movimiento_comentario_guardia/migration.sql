ALTER TABLE IF EXISTS movimientos
  ADD COLUMN IF NOT EXISTS comentario_guardia text;
