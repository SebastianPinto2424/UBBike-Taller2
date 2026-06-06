import { ErrorHttp } from '../../comun/errors/error-http';
import { prisma, type ClientePrisma } from '../../configuracion/prisma';
import { Prisma } from '../../generated/prisma/client';
import { RolUsuario } from '../usuarios/rol-usuario';
import { TipoNotificacion } from './tipo-notificacion';

type DatosCrearNotificacion = {
  usuarioId: string;
  titulo: string;
  mensaje: string;
  tipo?: TipoNotificacion;
  datos?: Record<string, unknown>;
};

type DatosNotificarRoles = {
  roles: RolUsuario[];
  titulo: string;
  mensaje: string;
  tipo?: TipoNotificacion;
  datos?: Record<string, unknown>;
};

type FiltrosNotificaciones = {
  cursor?: string;
  limite?: number;
  soloNoLeidas?: boolean;
};

const LIMITE_MAX = 50;
const LIMITE_DEFAULT = 20;

export const crearNotificacion = async (
  datos: DatosCrearNotificacion,
  db: ClientePrisma = prisma
) => {
  return db.notificacion.create({
    data: {
      usuarioId: datos.usuarioId,
      titulo: datos.titulo,
      mensaje: datos.mensaje,
      tipo: datos.tipo ?? TipoNotificacion.SISTEMA,
      datos: datos.datos as Prisma.InputJsonValue | undefined
    }
  });
};

export const notificarUsuariosPorRol = async (
  datos: DatosNotificarRoles,
  db: ClientePrisma = prisma
) => {
  const usuarios = await db.usuario.findMany({
    where: {
      rol: {
        in: datos.roles
      }
    },
    select: {
      id: true
    }
  });

  await Promise.allSettled(
    usuarios.map((usuario) =>
      crearNotificacion(
        {
          usuarioId: usuario.id,
          titulo: datos.titulo,
          mensaje: datos.mensaje,
          tipo: datos.tipo,
          datos: datos.datos
        },
        db
      )
    )
  );
};

export const listarNotificacionesUsuario = async (
  usuarioId: string,
  filtros: FiltrosNotificaciones = {}
) => {
  const limite = Math.min(filtros.limite ?? LIMITE_DEFAULT, LIMITE_MAX);

  const where: Prisma.NotificacionWhereInput = {
    usuarioId,
    ...(filtros.soloNoLeidas ? { leida: false } : {})
  };

  const notificaciones = await prisma.notificacion.findMany({
    where,
    orderBy: { creadaEn: 'desc' },
    take: limite + 1,
    ...(filtros.cursor
      ? {
          cursor: { id: filtros.cursor },
          skip: 1
        }
      : {})
  });

  const hayMas = notificaciones.length > limite;
  const items = hayMas ? notificaciones.slice(0, limite) : notificaciones;
  const nextCursor = hayMas ? items[items.length - 1].id : null;

  const noLeidas = await prisma.notificacion.count({
    where: { usuarioId, leida: false }
  });

  return {
    notificaciones: items,
    nextCursor,
    noLeidas
  };
};

export const marcarNotificacionLeida = async (usuarioId: string, notificacionId: string) => {
  const notificacion = await prisma.notificacion.findFirst({
    where: {
      id: notificacionId,
      usuarioId
    }
  });

  if (!notificacion) {
    throw new ErrorHttp(404, 'Notificación no encontrada');
  }

  return prisma.notificacion.update({
    where: {
      id: notificacion.id
    },
    data: {
      leida: true
    }
  });
};

export const marcarTodasLeidas = async (usuarioId: string) => {
  await prisma.notificacion.updateMany({
    where: {
      usuarioId,
      leida: false
    },
    data: {
      leida: true
    }
  });

  return {
    message: 'Notificaciones marcadas como leídas'
  };
};
