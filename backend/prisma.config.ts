import dotenv from 'dotenv';
import { defineConfig } from 'prisma/config';

dotenv.config();

const valorEntorno = (nombre: string, valorPorDefecto: string) =>
  process.env[nombre] ?? valorPorDefecto;

const construirUrlBaseDatos = () => {
  if (process.env.DATABASE_URL) {
    return process.env.DATABASE_URL;
  }

  const usuario = encodeURIComponent(valorEntorno('DB_USER', 'ubbike'));
  const contrasena = encodeURIComponent(valorEntorno('DB_PASSWORD', ''));
  const host = valorEntorno('DB_HOST', 'localhost');
  const puerto = valorEntorno('DB_PORT', '5432');
  const nombre = encodeURIComponent(valorEntorno('DB_NAME', 'ubbike'));

  return `postgresql://${usuario}:${contrasena}@${host}:${puerto}/${nombre}?schema=public`;
};

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations'
  },
  datasource: {
    url: construirUrlBaseDatos()
  }
});
