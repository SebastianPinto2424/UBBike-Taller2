CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'usuarios_rol_enum') THEN
    CREATE TYPE usuarios_rol_enum AS ENUM (
      'ESTUDIANTE',
      'FUNCIONARIO',
      'GUARDIA',
      'ADMIN_CENTRAL',
      'ADMINISTRADOR'
    );
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS usuarios (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  nombre varchar(120) NOT NULL,
  correo varchar(160) NOT NULL UNIQUE,
  rut varchar(20) UNIQUE,
  rol usuarios_rol_enum NOT NULL DEFAULT 'ESTUDIANTE',
  contrasena_hash varchar(255) NOT NULL,
  correo_verificado boolean NOT NULL DEFAULT false,
  cuenta_activa boolean NOT NULL DEFAULT true,
  version_sesion integer NOT NULL DEFAULT 0,
  token_verificacion_correo varchar(120),
  token_verificacion_correo_expira_en timestamptz,
  token_cambio_contrasena varchar(120),
  token_cambio_contrasena_expira_en timestamptz,
  creado_en timestamptz NOT NULL DEFAULT now(),
  actualizado_en timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS bicicleteros (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  nombre varchar(120) NOT NULL UNIQUE,
  ubicacion varchar(255) NOT NULL,
  capacidad integer NOT NULL DEFAULT 80,
  activo boolean NOT NULL DEFAULT true,
  creado_en timestamptz NOT NULL DEFAULT now(),
  actualizado_en timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS bicicletas (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  usuario_id uuid NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  descripcion varchar(255) NOT NULL,
  marca varchar(80),
  modelo varchar(80),
  color varchar(60),
  aro varchar(30),
  numero_serie varchar(120),
  foto_url text,
  activa boolean NOT NULL DEFAULT false,
  dentro_bicicletero boolean NOT NULL DEFAULT false,
  bicicletero_actual_id uuid REFERENCES bicicleteros(id),
  creado_en timestamptz NOT NULL DEFAULT now(),
  actualizado_en timestamptz NOT NULL DEFAULT now(),
  eliminado_en timestamptz
);

CREATE INDEX IF NOT EXISTS idx_bicicletas_usuario ON bicicletas(usuario_id);
CREATE INDEX IF NOT EXISTS idx_bicicletas_bicicletero_actual ON bicicletas(bicicletero_actual_id);
