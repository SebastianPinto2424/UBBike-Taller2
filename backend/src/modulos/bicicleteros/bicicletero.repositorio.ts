import { prisma, type ClientePrisma } from '../../configuracion/prisma';

const filtroOcupacion = {
  dentroBicicletero: true,
  eliminadoEn: null
} as const;

export const listarActivos = (client: ClientePrisma = prisma) =>
  client.bicicletero.findMany({
    where: { activo: true },
    orderBy: { nombre: 'asc' }
  });

export const contarOcupadosAgrupados = (client: ClientePrisma = prisma) =>
  client.bicicleta.groupBy({
    by: ['bicicleteroActualId'],
    where: { ...filtroOcupacion, bicicleteroActualId: { not: null } },
    _count: { _all: true }
  });

export const contarOcupados = (bicicleteroId: string, client: ClientePrisma = prisma) =>
  client.bicicleta.count({
    where: { ...filtroOcupacion, bicicleteroActualId: bicicleteroId }
  });
