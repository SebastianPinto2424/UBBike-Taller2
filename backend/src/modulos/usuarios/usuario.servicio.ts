import { ErrorHttp } from '../../comun/errors/error-http';
import { prisma } from '../../configuracion/prisma';
import { registrarAuditoria } from '../auditoria/auditoria.servicio';
import { crearNotificacion } from '../notificaciones/notificacion.servicio';
import { TipoNotificacion } from '../notificaciones/tipo-notificacion';
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

type FiltrosListarUsuarios = {
  q?: string;
  rol?: RolUsuario;
  cuentaActiva?: boolean;
  correoVerificado?: boolean;
};

export const listarUsuarios = async (filtros: FiltrosListarUsuarios = {}) => {
  const q = filtros.q?.trim();
  if (filtros.rol === RolUsuario.ADMIN_CENTRAL) {
    return [];
  }

  const usuarios = await prisma.usuario.findMany({
    where: {
      ...(filtros.rol ? { rol: filtros.rol } : { rol: { not: RolUsuario.ADMIN_CENTRAL } }),
      ...(filtros.cuentaActiva !== undefined ? { cuentaActiva: filtros.cuentaActiva } : {}),
      ...(filtros.correoVerificado !== undefined
        ? { correoVerificado: filtros.correoVerificado }
        : {}),
      ...(q
        ? {
            OR: [
              { nombre: { contains: q, mode: 'insensitive' } },
              { correo: { contains: q, mode: 'insensitive' } },
              { rut: { contains: q, mode: 'insensitive' } }
            ]
          }
        : {})
    },
    orderBy: {
      creadoEn: 'desc'
    }
  });

  return usuarios.map(mapearUsuarioPublico);
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

  if (usuario.rol === RolUsuario.ADMIN_CENTRAL) {
    throw new ErrorHttp(403, 'El admin general no gestiona cuentas de admin central');
  }

  if (datos.rol === RolUsuario.ADMIN_CENTRAL) {
    throw new ErrorHttp(400, 'El rol admin central no esta disponible');
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
    invalidarSesiones = invalidarSesiones || usuario.correo !== correoNormalizado;
    datosActualizacion.correo = correoNormalizado;
  }

  if (datos.rut !== undefined) {
    datosActualizacion.rut = datos.rut || null;
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

  await crearNotificacion({
    usuarioId: usuarioGuardado.id,
    titulo: 'Cuenta actualizada',
    mensaje: `Administración actualizó tu cuenta. Rol actual: ${usuarioGuardado.rol}.`,
    tipo: TipoNotificacion.CUENTA,
    datos: {
      rol: usuarioGuardado.rol,
      cuentaActiva: usuarioGuardado.cuentaActiva,
      correoVerificado: usuarioGuardado.correoVerificado
    }
  });

  await registrarAuditoria({
    actorUsuarioId: actorUsuarioId ?? null,
    accion: 'USUARIO_ACTUALIZADO_ADMIN',
    entidad: 'usuarios',
    entidadId: usuarioGuardado.id,
    datos: {
      campos: Object.keys(datos),
      rol: usuarioGuardado.rol,
      cuentaActiva: usuarioGuardado.cuentaActiva,
      correoVerificado: usuarioGuardado.correoVerificado,
      sesionesInvalidadas: invalidarSesiones
    }
  });

  return mapearUsuarioPublico(usuarioGuardado);
};
