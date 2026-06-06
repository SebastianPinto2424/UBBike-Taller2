import { prisma } from '../../configuracion/prisma';
import { construirStatsBicicletero, contarOcupadosPorBicicletero } from './bicicletero.ocupacion';

export const listarBicicleteros = async () => {
  const [bicicleteros, ocupadosPorId] = await Promise.all([
    prisma.bicicletero.findMany({
      where: { activo: true },
      orderBy: { nombre: 'asc' }
    }),
    contarOcupadosPorBicicletero()
  ]);

  return bicicleteros.map((bicicletero) =>
    construirStatsBicicletero(bicicletero, ocupadosPorId[bicicletero.id] ?? 0)
  );
};
