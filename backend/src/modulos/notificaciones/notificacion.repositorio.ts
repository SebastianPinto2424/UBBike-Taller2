import { Prisma } from '../../generated/prisma/client';
import { prisma, type ClientePrisma } from '../../configuracion/prisma';
import { RolUsuario } from '../usuarios/rol-usuario';

export const crear = (
  data: Prisma.NotificacionUncheckedCreateInput,
  client: ClientePrisma = prisma
) => client.notificacion.create({ data });

export const buscarIdsPorRoles = (roles: RolUsuario[], client: ClientePrisma = prisma) =>
  client.usuario.findMany({
    where: { rol: { in: roles } },
    select: { id: true }
  });

export const listarDeUsuario = (
  params: { usuarioId: string; soloNoLeidas: boolean; take: number; cursor?: string },
  client: ClientePrisma = prisma
) =>
  client.notificacion.findMany({
    where: {
      usuarioId: params.usuarioId,
      ...(params.soloNoLeidas ? { leida: false } : {})
    },
    orderBy: { creadaEn: 'desc' },
    take: params.take,
    ...(params.cursor
      ? {
          cursor: { id: params.cursor },
          skip: 1
        }
      : {})
  });

export const contarNoLeidas = (usuarioId: string, client: ClientePrisma = prisma) =>
  client.notificacion.count({ where: { usuarioId, leida: false } });

export const buscarDeUsuario = (usuarioId: string, id: string, client: ClientePrisma = prisma) =>
  client.notificacion.findFirst({ where: { id, usuarioId } });

export const marcarLeida = (id: string, client: ClientePrisma = prisma) =>
  client.notificacion.update({ where: { id }, data: { leida: true } });

export const marcarTodasLeidas = (usuarioId: string, client: ClientePrisma = prisma) =>
  client.notificacion.updateMany({
    where: { usuarioId, leida: false },
    data: { leida: true }
  });
