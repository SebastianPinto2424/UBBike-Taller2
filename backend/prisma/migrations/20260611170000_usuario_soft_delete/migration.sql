ALTER TABLE "usuarios"
  ADD COLUMN IF NOT EXISTS "eliminado_en" TIMESTAMPTZ(6);

CREATE INDEX IF NOT EXISTS "idx_usuarios_eliminado_en"
  ON "usuarios"("eliminado_en");
