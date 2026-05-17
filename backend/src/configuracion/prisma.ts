import { PrismaPg } from '@prisma/adapter-pg';
import { Prisma, PrismaClient } from '../generated/prisma/client';
import { entorno } from './entorno';

const adapter = new PrismaPg({
  connectionString: entorno.baseDatos.url
});

export const prisma = new PrismaClient({
  adapter,
  log: entorno.ambiente === 'development' ? ['error', 'warn'] : ['error']
});

export type ClientePrisma = Prisma.TransactionClient | PrismaClient;
