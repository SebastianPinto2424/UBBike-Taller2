import { prisma, type ClientePrisma } from '../../configuracion/prisma';
import type { Bicicletero } from '../../generated/prisma/client';

const filtroOcupacion = {
  dentroBicicletero: true,
  eliminadoEn: null
} as const;

export type StatsBicicletero = {
  id: string;
  nombre: string;
  ubicacion: string;
  capacidad: number;
  ocupados: number;
  cuposDisponibles: number;
  porcentajeUso: number;
};

export const contarOcupadosPorBicicletero = async (
  db: ClientePrisma = prisma
): Promise<Record<string, number>> => {
  const grupos = await db.bicicleta.groupBy({
    by: ['bicicleteroActualId'],
    where: { ...filtroOcupacion, bicicleteroActualId: { not: null } },
    _count: { _all: true }
  });

  return Object.fromEntries(
    grupos
      .filter((grupo) => grupo.bicicleteroActualId)
      .map((grupo) => [grupo.bicicleteroActualId!, grupo._count._all])
  );
};

export const contarOcupadosBicicletero = async (
  bicicleteroId: string,
  db: ClientePrisma = prisma
): Promise<number> =>
  db.bicicleta.count({
    where: { ...filtroOcupacion, bicicleteroActualId: bicicleteroId }
  });

export const construirStatsBicicletero = (
  bicicletero: Bicicletero,
  ocupados: number
): StatsBicicletero => {
  const capacidad = Math.max(bicicletero.capacidad, 1);

  return {
    id: bicicletero.id,
    nombre: bicicletero.nombre,
    ubicacion: bicicletero.ubicacion,
    capacidad,
    ocupados,
    cuposDisponibles: Math.max(capacidad - ocupados, 0),
    porcentajeUso: Math.min(Math.round((ocupados / capacidad) * 100), 100)
  };
};
