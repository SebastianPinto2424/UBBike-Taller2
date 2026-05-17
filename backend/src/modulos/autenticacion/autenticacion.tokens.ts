import crypto from 'crypto';
import jwt, { SignOptions } from 'jsonwebtoken';
import { ErrorHttp } from '../../comun/errors/error-http';
import { entorno } from '../../configuracion/entorno';
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

  throw new ErrorHttp(400, 'Debes usar un correo institucional UBB valido');
};
