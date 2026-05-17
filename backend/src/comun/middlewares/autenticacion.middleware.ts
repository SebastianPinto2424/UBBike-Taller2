import { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { entorno } from '../../configuracion/entorno';
import { prisma } from '../../configuracion/prisma';

export type CargaToken = {
  usuarioId: string;
  rol: string;
  versionSesion: number;
};

declare module 'express-serve-static-core' {
  interface Request {
    usuario?: CargaToken;
  }
}

export type SolicitudAutenticada = Request & {
  usuario?: CargaToken;
};

export const middlewareAutenticacion = async (
  req: SolicitudAutenticada,
  res: Response,
  next: NextFunction
): Promise<Response | void> => {
  const autorizacion = req.headers.authorization;

  if (!autorizacion?.startsWith('Bearer ')) {
    return res.status(401).json({
      message: 'Token de autenticación requerido'
    });
  }

  const token = autorizacion.replace('Bearer ', '');

  try {
    const carga = jwt.verify(token, entorno.jwt.secreto, {
      algorithms: ['HS256'],
      audience: entorno.jwt.audiencia,
      issuer: entorno.jwt.emisor
    }) as CargaToken;

    const usuario = await prisma.usuario.findUnique({
      where: {
        id: carga.usuarioId
      }
    });

    if (!usuario || !usuario.cuentaActiva || !usuario.correoVerificado) {
      return res.status(401).json({
        message: 'Token de autenticación inválido o expirado'
      });
    }

    if (usuario.versionSesion !== carga.versionSesion) {
      return res.status(401).json({
        message: 'La sesión fue invalidada. Inicia sesión nuevamente.'
      });
    }

    req.usuario = {
      usuarioId: usuario.id,
      rol: usuario.rol,
      versionSesion: usuario.versionSesion
    };
    return next();
  } catch {
    return res.status(401).json({
      message: 'Token de autenticación inválido o expirado'
    });
  }
};
