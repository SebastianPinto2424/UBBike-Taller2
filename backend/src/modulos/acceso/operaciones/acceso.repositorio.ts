import { Prisma } from '../../../generated/prisma/client';
import { prisma, type ClientePrisma } from '../../../configuracion/prisma';
import { includeMovimientoCompleto } from './acceso.mapeador';

export const ejecutarEnTransaccion = <T>(callback: (client: ClientePrisma) => Promise<T>) =>
  prisma.$transaction(callback);

export const buscarAsignacionActiva = (
  guardiaId: string,
  bicicleteroId: string,
  client: ClientePrisma = prisma
) =>
  client.asignacionGuardia.findFirst({
    where: {
      guardiaId,
      bicicleteroId,
      activa: true
    }
  });

export const buscarAsignacionActivaConBicicletero = (
  guardiaId: string,
  client: ClientePrisma = prisma
) =>
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

export const buscarBicicletero = (id: string, client: ClientePrisma = prisma) =>
  client.bicicletero.findUnique({
    where: { id }
  });

export const marcarQrUsado = (codigoQrId: string, client: ClientePrisma = prisma) =>
  client.codigoQrTemporal.updateMany({
    where: {
      id: codigoQrId,
      usado: false
    },
    data: {
      usado: true
    }
  });

export const crearMovimiento = (
  data: Prisma.MovimientoUncheckedCreateInput,
  client: ClientePrisma = prisma
) => client.movimiento.create({ data });

export const actualizarBicicleta = (
  id: string,
  data: Prisma.BicicletaUncheckedUpdateInput,
  client: ClientePrisma = prisma
) =>
  client.bicicleta.update({
    where: { id },
    data
  });

export const buscarMovimientoCompleto = (id: string, client: ClientePrisma = prisma) =>
  client.movimiento.findUniqueOrThrow({
    where: { id },
    include: includeMovimientoCompleto
  });

export const desactivarBicicletasDeUsuario = (usuarioId: string, client: ClientePrisma = prisma) =>
  client.bicicleta.updateMany({
    where: {
      usuarioId,
      eliminadoEn: null
    },
    data: {
      activa: false
    }
  });

export const crearBicicleta = (
  data: Prisma.BicicletaUncheckedCreateInput,
  client: ClientePrisma = prisma
) =>
  client.bicicleta.create({
    data,
    include: {
      bicicleteroActual: true
    }
  });

export const buscarUsuarioGestionManual = (
  criterios: Prisma.UsuarioWhereInput[],
  client: ClientePrisma = prisma
) =>
  client.usuario.findFirst({
    where: {
      OR: criterios
    },
    include: {
      bicicletas: {
        where: {
          eliminadoEn: null
        },
        include: {
          bicicleteroActual: true
        },
        orderBy: [{ activa: 'desc' }, { dentroBicicletero: 'desc' }, { creadoEn: 'desc' }]
      }
    }
  });

export const buscarUsuarioPorCriterios = (
  criterios: Prisma.UsuarioWhereInput[],
  client: ClientePrisma = prisma
) =>
  client.usuario.findFirst({
    where: {
      OR: criterios
    }
  });

export const crearUsuario = (
  data: Prisma.UsuarioUncheckedCreateInput,
  client: ClientePrisma = prisma
) => client.usuario.create({ data });

export const actualizarUsuario = (
  id: string,
  data: Prisma.UsuarioUpdateInput,
  client: ClientePrisma = prisma
) =>
  client.usuario.update({
    where: { id },
    data
  });

export const buscarBicicletaParaGestionManual = (
  where: Prisma.BicicletaWhereInput,
  client: ClientePrisma = prisma
) =>
  client.bicicleta.findFirst({
    where,
    include: {
      bicicleteroActual: true
    }
  });
