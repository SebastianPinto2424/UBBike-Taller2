import { ErrorHttp } from '../../comun/errors/error-http';
import type { ClientePrisma } from '../../configuracion/prisma';
import { Prisma } from '../../generated/prisma/client';
import { RolUsuario } from '../usuarios/rol-usuario';
import { EventosTiempoReal, emitirTiempoReal, salaUsuario } from '../../tiempo-real/tiempo-real';
import { TipoNotificacion } from './tipo-notificacion';
import * as notificacionRepositorio from './notificacion.repositorio';

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

export const crearNotificacion = async (datos: DatosCrearNotificacion, db?: ClientePrisma) => {
  const notificacion = await notificacionRepositorio.crear(
    {
      usuarioId: datos.usuarioId,
      titulo: datos.titulo,
      mensaje: datos.mensaje,
      tipo: datos.tipo ?? TipoNotificacion.SISTEMA,
      datos: datos.datos as Prisma.InputJsonValue | undefined
    },
    db
  );

  emitirTiempoReal([salaUsuario(datos.usuarioId)], EventosTiempoReal.NOTIFICACION, {
    accion: 'creada',
    notificacionId: notificacion.id
  });

  return notificacion;
};

export const notificarUsuariosPorRol = async (datos: DatosNotificarRoles, db?: ClientePrisma) => {
  const usuarios = await notificacionRepositorio.buscarIdsPorRoles(datos.roles, db);

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

  const notificaciones = await notificacionRepositorio.listarDeUsuario({
    usuarioId,
    soloNoLeidas: filtros.soloNoLeidas ?? false,
    take: limite + 1,
    cursor: filtros.cursor
  });

  const hayMas = notificaciones.length > limite;
  const items = hayMas ? notificaciones.slice(0, limite) : notificaciones;
  const nextCursor = hayMas ? items[items.length - 1].id : null;

  const noLeidas = await notificacionRepositorio.contarNoLeidas(usuarioId);

  return {
    notificaciones: items,
    nextCursor,
    noLeidas
  };
};

export const marcarNotificacionLeida = async (usuarioId: string, notificacionId: string) => {
  const notificacion = await notificacionRepositorio.buscarDeUsuario(usuarioId, notificacionId);

  if (!notificacion) {
    throw new ErrorHttp(404, 'Notificación no encontrada');
  }

  const notificacionActualizada = await notificacionRepositorio.marcarLeida(notificacion.id);

  emitirTiempoReal([salaUsuario(usuarioId)], EventosTiempoReal.NOTIFICACION, {
    accion: 'leida',
    notificacionId: notificacion.id
  });

  return notificacionActualizada;
};

export const marcarTodasLeidas = async (usuarioId: string) => {
  await notificacionRepositorio.marcarTodasLeidas(usuarioId);

  emitirTiempoReal([salaUsuario(usuarioId)], EventosTiempoReal.NOTIFICACION, {
    accion: 'todas_leidas'
  });

  return {
    message: 'Notificaciones marcadas como leídas'
  };
};
