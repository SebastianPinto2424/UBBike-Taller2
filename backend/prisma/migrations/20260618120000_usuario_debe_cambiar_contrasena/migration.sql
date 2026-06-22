-- Marca cuentas creadas por el administrador (p. ej. guardias) con contraseña
-- temporal que el usuario debe cambiar en su primer inicio de sesión.
ALTER TABLE "usuarios"
  ADD COLUMN "debe_cambiar_contrasena" BOOLEAN NOT NULL DEFAULT false;
