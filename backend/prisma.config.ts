import dotenv from 'dotenv';
import path from 'path';
import { defineConfig } from 'prisma/config';

const cargarVariablesEntorno = () => {
  const rutas = [
    path.resolve(process.cwd(), '.env'),
    path.resolve(process.cwd(), 'backend', '.env'),
    path.resolve(process.cwd(), '..', '.env')
  ];

  for (const ruta of rutas) {
    dotenv.config({ path: ruta });
  }
};

cargarVariablesEntorno();

const valorEntorno = (principal: string, valorPorDefecto: string, alternativo?: string) =>
  process.env[principal] ?? (alternativo ? process.env[alternativo] : undefined) ?? valorPorDefecto;

const construirUrlBaseDatos = () => {
  if (process.env.DATABASE_URL) {
    return process.env.DATABASE_URL;
  }

  const usuario = encodeURIComponent(valorEntorno('DB_USER', 'ubbike', 'POSTGRES_USER'));
  const contrasena = encodeURIComponent(valorEntorno('DB_PASSWORD', '', 'POSTGRES_PASSWORD'));
  const host = valorEntorno('DB_HOST', 'localhost');
  const puerto = valorEntorno('DB_PORT', '5432', 'POSTGRES_PORT');
  const nombre = encodeURIComponent(valorEntorno('DB_NAME', 'ubbike', 'POSTGRES_DB'));

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
