import { NextFunction, Request, Response } from 'express';
import { entorno } from '../../configuracion/entorno';
import { obtenerClienteRedis } from '../../configuracion/redis';

type OpcionesLimitador = {
  ventanaMs: number;
  maximo: number;
  mensaje: string;
};

type RegistroIntentos = {
  cantidad: number;
  reiniciaEn: number;
};

const intentos = new Map<string, RegistroIntentos>();

const limitarConMemoria = (
  clave: string,
  opciones: OpcionesLimitador,
  ahora: number,
  res: Response,
  next: NextFunction
) => {
  const registro = intentos.get(clave);

  if (!registro || registro.reiniciaEn <= ahora) {
    intentos.set(clave, {
      cantidad: 1,
      reiniciaEn: ahora + opciones.ventanaMs
    });
    return next();
  }

  if (registro.cantidad >= opciones.maximo) {
    const segundos = Math.ceil((registro.reiniciaEn - ahora) / 1000);
    res.setHeader('Retry-After', segundos.toString());
    return res.status(429).json({
      message: opciones.mensaje
    });
  }

  registro.cantidad += 1;
  intentos.set(clave, registro);
  return next();
};

export const limitarIntentos =
  (opciones: OpcionesLimitador) => async (req: Request, res: Response, next: NextFunction) => {
    const ahora = Date.now();
    const clave = `${req.ip}:${req.path}`;

    try {
      const redis = await obtenerClienteRedis();

      if (!redis) {
        return limitarConMemoria(clave, opciones, ahora, res, next);
      }

      const claveRedis = `rate-limit:${clave}`;
      const cantidad = await redis.incr(claveRedis);

      if (cantidad === 1) {
        await redis.pExpire(claveRedis, opciones.ventanaMs);
      }

      if (cantidad > opciones.maximo) {
        const ttlMs = await redis.pTTL(claveRedis);
        const segundos = Math.max(Math.ceil(ttlMs / 1000), 1);
        res.setHeader('Retry-After', segundos.toString());
        return res.status(429).json({
          message: opciones.mensaje
        });
      }

      return next();
    } catch (error) {
      console.error('No se pudo aplicar rate limiting distribuido', error);

      if (entorno.redis.requerirParaLimitador) {
        return res.status(503).json({
          message: 'Protección temporal no disponible. Intenta nuevamente más tarde.'
        });
      }

      return limitarConMemoria(clave, opciones, ahora, res, next);
    }
  };
