import { Prisma } from '../../../generated/prisma/client';
import { prisma, type ClientePrisma } from '../../../configuracion/prisma';

export const ejecutarEnTransaccion = <T>(callback: (client: ClientePrisma) => Promise<T>) =>
  prisma.$transaction(callback);

export const buscarActivaConBicicletero = (guardiaId: string, client: ClientePrisma = prisma) =>
  client.asignacionGuardia.findFirst({
    where: {
      guardiaId,
      activa: true
    },
    include: {
      bicicletero: true
    },
    orderBy: {
      iniciaEn: 'desc'
    }
  });

export const buscarBicicleteroActivo = (id: string, client: ClientePrisma = prisma) =>
  client.bicicletero.findFirst({
    where: {
      id,
      activo: true
    }
  });

export const cerrarActivasDeGuardia = (
  guardiaId: string,
  terminaEn: Date,
  client: ClientePrisma = prisma
) =>
  client.asignacionGuardia.updateMany({
    where: {
      guardiaId,
      activa: true
    },
    data: {
      activa: false,
      terminaEn
    }
  });

export const crear = (
  data: Prisma.AsignacionGuardiaUncheckedCreateInput,
  client: ClientePrisma = prisma
) => client.asignacionGuardia.create({ data });
