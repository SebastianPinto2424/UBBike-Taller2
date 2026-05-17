import { prisma } from '../../configuracion/prisma';

export const listarBicicleteros = async () => {
  const bicicleteros = await prisma.bicicletero.findMany({
    where: {
      activo: true
    },
    orderBy: {
      nombre: 'asc'
    }
  });

  return Promise.all(
    bicicleteros.map(async (bicicletero) => {
      const ocupados = await prisma.bicicleta.count({
        where: {
          dentroBicicletero: true,
          bicicleteroActualId: bicicletero.id,
          eliminadoEn: null
        }
      });
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
    })
  );
};
