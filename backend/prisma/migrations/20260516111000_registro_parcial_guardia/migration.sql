ALTER TABLE IF EXISTS usuarios
  ADD COLUMN IF NOT EXISTS registro_parcial boolean NOT NULL DEFAULT false;
