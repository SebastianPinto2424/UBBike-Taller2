import crypto from 'crypto';
import jwt, { SignOptions } from 'jsonwebtoken';
import { ErrorHttp } from '../../comun/errors/error-http';
import { entorno } from '../../configuracion/entorno';
import { obtenerClienteRedis } from '../../configuracion/redis';
import { RolUsuario } from '../usuarios/rol-usuario';

export const horasExpiracionVerificacionCorreo = 24;

export const crearTokenSeguro = (): string => crypto.randomBytes(32).toString('hex');

export const hashearToken = (token: string): string =>
  crypto.createHash('sha256').update(token).digest('hex');

export const crearTokenSesion = (
  usuarioId: string,
  rol: RolUsuario,
  versionSesion: number
): string => {
  const opcionesFirma: SignOptions = {
    expiresIn: entorno.jwt.expiracion as SignOptions['expiresIn'],
    issuer: entorno.jwt.emisor,
    audience: entorno.jwt.audiencia
  };

  return jwt.sign({ usuarioId, rol, versionSesion }, entorno.jwt.secreto, opcionesFirma);
};

export const resolverRolRegistrable = (correo: string): RolUsuario => {
  if (correo.endsWith('@alumnos.ubiobio.cl')) {
    return RolUsuario.ESTUDIANTE;
  }

  if (correo.endsWith('@ubiobio.cl')) {
    return RolUsuario.FUNCIONARIO;
  }

  throw new ErrorHttp(400, 'Debes usar un correo institucional UBB válido');
};

const claveRefreshToken = (usuarioId: string, tokenHash: string) =>
  `refresh:${usuarioId}:${tokenHash}`;

export const crearRefreshToken = (): string => crypto.randomBytes(48).toString('base64url');

export const guardarRefreshToken = async (usuarioId: string, token: string): Promise<void> => {
  const redis = await obtenerClienteRedis();

  if (!redis) {
    return;
  }

  const hash = hashearToken(token);
  const clave = claveRefreshToken(usuarioId, hash);
  const ttlSegundos = entorno.jwt.refreshExpiracionDias * 24 * 60 * 60;

  await redis.set(clave, '1', { EX: ttlSegundos });
};

export const validarRefreshToken = async (usuarioId: string, token: string): Promise<boolean> => {
  const redis = await obtenerClienteRedis();

  if (!redis) {
    throw new ErrorHttp(503, 'Servicio de sesión no disponible. Intenta nuevamente.');
  }

  const hash = hashearToken(token);
  const clave = claveRefreshToken(usuarioId, hash);
  const valor = await redis.get(clave);

  return valor === '1';
};

export const revocarRefreshToken = async (usuarioId: string, token: string): Promise<void> => {
  const redis = await obtenerClienteRedis();

  if (!redis) {
    return;
  }

  const hash = hashearToken(token);
  const clave = claveRefreshToken(usuarioId, hash);
  await redis.del(clave);
};

export const revocarTodosLosRefreshTokens = async (usuarioId: string): Promise<void> => {
  const redis = await obtenerClienteRedis();

  if (!redis) {
    return;
  }

  const patron = `refresh:${usuarioId}:*`;
  let cursor = '0';

  do {
    const resultado = await redis.scan(cursor, { MATCH: patron, COUNT: 100 });
    cursor = String(resultado.cursor);

    if (resultado.keys.length > 0) {
      await redis.del(resultado.keys);
    }
  } while (cursor !== '0');
};
