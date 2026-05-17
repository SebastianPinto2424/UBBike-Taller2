import { ErrorHttp } from '../../comun/errors/error-http';
import { prisma } from '../../configuracion/prisma';
import { mapearUsuarioPublico } from './usuario.mapeador';
import { RolUsuario } from './rol-usuario';

type DatosActualizarPermisos = {
  nombre?: string;
  correo?: string;
  rut?: string | null;
  rol?: RolUsuario;
  cuentaActiva?: boolean;
  correoVerificado?: boolean;
};

export const listarUsuarios = async () => {
  const usuarios = await prisma.usuario.findMany({
    orderBy: {
      creadoEn: 'desc'
    }
  });

  return usuarios.map(mapearUsuarioPublico);
};

const asegurarCorreoDisponible = async (correo: string, usuarioId: string) => {
  const existente = await prisma.usuario.findUnique({
    where: {
      correo
    }
  });

  if (existente && existente.id !== usuarioId) {
    throw new ErrorHttp(409, 'El correo ya está registrado');
  }
};

const asegurarRutDisponible = async (rut: string | null, usuarioId: string) => {
  if (!rut) {
    return;
  }

  const existente = await prisma.usuario.findUnique({
    where: {
      rut
    }
  });

  if (existente && existente.id !== usuarioId) {
    throw new ErrorHttp(409, 'El RUT ya está registrado');
  }
};

export const actualizarPermisosUsuario = async (
  usuarioId: string,
  datos: DatosActualizarPermisos,
  actorUsuarioId?: string
) => {
  const usuario = await prisma.usuario.findUnique({
    where: {
      id: usuarioId
    }
  });

  if (!usuario) {
    throw new ErrorHttp(404, 'Usuario no encontrado');
  }

  if (actorUsuarioId === usuarioId && datos.cuentaActiva === false) {
    throw new ErrorHttp(400, 'No puedes desactivar tu propia cuenta');
  }

  let invalidarSesiones = false;
  const datosActualizacion: {
    nombre?: string;
    correo?: string;
    rut?: string | null;
    rol?: RolUsuario;
    cuentaActiva?: boolean;
    correoVerificado?: boolean;
    tokenVerificacionCorreo?: string | null;
    tokenVerificacionCorreoExpiraEn?: Date | null;
    versionSesion?: {
      increment: number;
    };
  } = {};

  if (datos.rol !== undefined) {
    invalidarSesiones = invalidarSesiones || usuario.rol !== datos.rol;
    datosActualizacion.rol = datos.rol;
  }

  if (datos.nombre !== undefined) {
    datosActualizacion.nombre = datos.nombre;
  }

  if (datos.correo !== undefined) {
    const correoNormalizado = datos.correo.toLowerCase();
    await asegurarCorreoDisponible(correoNormalizado, usuario.id);
    invalidarSesiones = invalidarSesiones || usuario.correo !== correoNormalizado;
    datosActualizacion.correo = correoNormalizado;
  }

  if (datos.rut !== undefined) {
    const rut = datos.rut || null;
    await asegurarRutDisponible(rut, usuario.id);
    datosActualizacion.rut = rut;
  }

  if (datos.cuentaActiva !== undefined) {
    invalidarSesiones = invalidarSesiones || usuario.cuentaActiva !== datos.cuentaActiva;
    datosActualizacion.cuentaActiva = datos.cuentaActiva;
  }

  if (datos.correoVerificado !== undefined) {
    invalidarSesiones = invalidarSesiones || usuario.correoVerificado !== datos.correoVerificado;
    datosActualizacion.correoVerificado = datos.correoVerificado;
    if (datos.correoVerificado) {
      datosActualizacion.tokenVerificacionCorreo = null;
      datosActualizacion.tokenVerificacionCorreoExpiraEn = null;
    }
  }

  if (invalidarSesiones) {
    datosActualizacion.versionSesion = {
      increment: 1
    };
  }

  const usuarioGuardado = await prisma.usuario.update({
    where: {
      id: usuario.id
    },
    data: datosActualizacion
  });

  return mapearUsuarioPublico(usuarioGuardado);
};
