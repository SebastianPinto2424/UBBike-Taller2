import type { Server as ServidorHttp } from 'http';
import jwt from 'jsonwebtoken';
import { Server, type Socket } from 'socket.io';
import { entorno } from '../configuracion/entorno';

type CargaToken = {
  usuarioId: string;
  rol: string;
  versionSesion: number;
};

export const EventosTiempoReal = {
  NOTIFICACION: 'notificacion',
  MOVIMIENTO: 'movimiento',
  SOLICITUD: 'solicitud',
  INCIDENCIA: 'incidencia',
  USUARIO: 'usuario'
} as const;

export const salaUsuario = (usuarioId: string) => `usuario:${usuarioId}`;
export const salaRol = (rol: string) => `rol:${rol}`;

let io: Server | null = null;

export const inicializarTiempoReal = (servidor: ServidorHttp): Server => {
  io = new Server(servidor, {
    cors: {
      origin: entorno.cors.origenes,
      credentials: false
    }
  });

  io.use((socket, next) => {
    const token = (socket.handshake.auth?.token as string | undefined) ?? '';

    if (!token) {
      return next(new Error('Token de tiempo real requerido'));
    }

    try {
      const carga = jwt.verify(token, entorno.jwt.secreto, {
        algorithms: ['HS256'],
        audience: entorno.jwt.audiencia,
        issuer: entorno.jwt.emisor
      }) as CargaToken;

      socket.data.usuarioId = carga.usuarioId;
      socket.data.rol = carga.rol;
      return next();
    } catch {
      return next(new Error('Token de tiempo real inválido'));
    }
  });

  io.on('connection', (socket: Socket) => {
    const usuarioId = socket.data.usuarioId as string;
    const rol = socket.data.rol as string;
    socket.join(salaUsuario(usuarioId));
    socket.join(salaRol(rol));
  });

  return io;
};

export const emitirTiempoReal = (
  salas: string[],
  evento: string,
  payload?: unknown
): void => {
  if (!io || salas.length === 0) {
    return;
  }

  io.to([...new Set(salas)]).emit(evento, payload ?? {});
};
