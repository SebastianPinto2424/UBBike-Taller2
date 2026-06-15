import bcrypt from 'bcryptjs';
import { ErrorHttp } from '../../comun/errors/error-http';
import * as usuarioRepositorio from './usuario.repositorio';
import { registrarAuditoria } from '../auditoria/auditoria.servicio';
import { crearNotificacion } from '../notificaciones/notificacion.servicio';
import { TipoNotificacion } from '../notificaciones/tipo-notificacion';
import { mapearUsuarioPublico } from './usuario.mapeador';
import { RolUsuario } from './rol-usuario';
import {
  EventosTiempoReal,
  emitirTiempoReal,
  salaRol
} from '../../tiempo-real/tiempo-real';

const emitirCambioUsuarios = () =>
  emitirTiempoReal([salaRol(RolUsuario.ADMINISTRADOR)], EventosTiempoReal.USUARIO);

type DatosCrearUsuario = {
  nombre: string;
  correo: string;
  rut?: string | null;
  rol: RolUsuario;
  contrasena: string;
};

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

const asegurarNoEsUltimoAdministrador = async (usuarioId: string) => {
  const administradoresRestantes = await usuarioRepositorio.contarAdministradoresActivos(usuarioId);

  if (administradoresRestantes === 0) {
    throw new ErrorHttp(400, 'Debe existir al menos un administrador activo y verificado');
  }
};

export const listarUsuarios = async (filtros: FiltrosListarUsuarios = {}) => {
  const usuarios = await usuarioRepositorio.buscarUsuarios(filtros);

  return usuarios.map(mapearUsuarioPublico);
};

export const crearUsuarioAdmin = async (datos: DatosCrearUsuario, actorUsuarioId?: string) => {
  const correoNormalizado = datos.correo.trim().toLowerCase();
  const rut = datos.rut?.trim() ? datos.rut.trim() : null;

  const correoExistente = await usuarioRepositorio.buscarPorCorreo(correoNormalizado);
  if (correoExistente) {
    if (correoExistente.eliminadoEn) {
      if (rut) {
        const rutExistente = await usuarioRepositorio.buscarPorRut(rut);
        if (rutExistente && rutExistente.id !== correoExistente.id) {
          throw new ErrorHttp(409, 'El RUT ya está registrado');
        }
      }

      const contrasenaHash = await bcrypt.hash(datos.contrasena, 12);
      const usuarioRestaurado = await usuarioRepositorio.actualizar(correoExistente.id, {
        nombre: datos.nombre.trim(),
        rut,
        rol: datos.rol,
        contrasenaHash,
        correoVerificado: true,
        registroParcial: false,
        cuentaActiva: true,
        eliminadoEn: null,
        tokenVerificacionCorreo: null,
        tokenVerificacionCorreoExpiraEn: null,
        tokenCambioContrasena: null,
        tokenCambioContrasenaExpiraEn: null,
        versionSesion: {
          increment: 1
        }
      });

      await crearNotificacion({
        usuarioId: usuarioRestaurado.id,
        titulo: 'Cuenta reactivada',
        mensaje: 'Administración reactivó tu cuenta UBBike.',
        tipo: TipoNotificacion.CUENTA,
        datos: {
          rol: usuarioRestaurado.rol,
          cuentaActiva: usuarioRestaurado.cuentaActiva,
          correoVerificado: usuarioRestaurado.correoVerificado
        }
      });

      await registrarAuditoria({
        actorUsuarioId: actorUsuarioId ?? null,
        accion: 'USUARIO_RESTAURADO_ADMIN',
        entidad: 'usuarios',
        entidadId: usuarioRestaurado.id,
        datos: { correo: usuarioRestaurado.correo, rol: usuarioRestaurado.rol }
      });

      return mapearUsuarioPublico(usuarioRestaurado);
    }

    throw new ErrorHttp(409, 'El correo ya está registrado');
  }

  if (rut) {
    const rutExistente = await usuarioRepositorio.buscarPorRut(rut);
    if (rutExistente) {
      throw new ErrorHttp(409, 'El RUT ya está registrado');
    }
  }

  const contrasenaHash = await bcrypt.hash(datos.contrasena, 12);

  const usuarioGuardado = await usuarioRepositorio.crear({
    nombre: datos.nombre.trim(),
    correo: correoNormalizado,
    rut,
    rol: datos.rol,
    contrasenaHash,
    correoVerificado: true,
    registroParcial: false,
    cuentaActiva: true
  });

  await registrarAuditoria({
    actorUsuarioId: actorUsuarioId ?? null,
    accion: 'USUARIO_CREADO_ADMIN',
    entidad: 'usuarios',
    entidadId: usuarioGuardado.id,
    datos: { correo: usuarioGuardado.correo, rol: usuarioGuardado.rol }
  });

  emitirCambioUsuarios();

  return mapearUsuarioPublico(usuarioGuardado);
};

export const eliminarUsuarioAdmin = async (usuarioId: string, actorUsuarioId?: string) => {
  if (usuarioId === actorUsuarioId) {
    throw new ErrorHttp(400, 'No puedes eliminar tu propia cuenta');
  }

  const usuario = await usuarioRepositorio.buscarPorId(usuarioId);
  if (!usuario) {
    throw new ErrorHttp(404, 'Usuario no encontrado');
  }
  if (usuario.eliminadoEn) {
    throw new ErrorHttp(409, 'La cuenta ya fue eliminada');
  }
  if (usuario.rol === RolUsuario.ADMINISTRADOR) {
    await asegurarNoEsUltimoAdministrador(usuario.id);
  }

  const usuarioGuardado = await usuarioRepositorio.actualizar(usuario.id, {
    cuentaActiva: false,
    eliminadoEn: new Date(),
    tokenVerificacionCorreo: null,
    tokenVerificacionCorreoExpiraEn: null,
    tokenCambioContrasena: null,
    tokenCambioContrasenaExpiraEn: null,
    versionSesion: { increment: 1 }
  });

  await registrarAuditoria({
    actorUsuarioId: actorUsuarioId ?? null,
    accion: 'USUARIO_ELIMINADO_ADMIN',
    entidad: 'usuarios',
    entidadId: usuarioGuardado.id,
    datos: { correo: usuarioGuardado.correo }
  });

  emitirCambioUsuarios();

  return { message: 'Cuenta eliminada (desactivada y sesiones cerradas)' };
};

export const actualizarPermisosUsuario = async (
  usuarioId: string,
  datos: DatosActualizarPermisos,
  actorUsuarioId?: string
) => {
  const usuario = await usuarioRepositorio.buscarPorId(usuarioId);

  if (!usuario) {
    throw new ErrorHttp(404, 'Usuario no encontrado');
  }
  if (usuario.eliminadoEn) {
    throw new ErrorHttp(409, 'No puedes modificar una cuenta eliminada');
  }

  const dejaDeSerAdministradorActivo =
    usuario.rol === RolUsuario.ADMINISTRADOR &&
    ((datos.rol !== undefined && datos.rol !== RolUsuario.ADMINISTRADOR) ||
      datos.cuentaActiva === false ||
      datos.correoVerificado === false);

  if (dejaDeSerAdministradorActivo) {
    await asegurarNoEsUltimoAdministrador(usuario.id);
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
    const correoNormalizado = datos.correo.trim().toLowerCase();
    const correoExistente = await usuarioRepositorio.buscarPorCorreo(correoNormalizado);
    if (correoExistente && correoExistente.id !== usuario.id) {
      throw new ErrorHttp(409, 'El correo ya está registrado');
    }
    invalidarSesiones = invalidarSesiones || usuario.correo !== correoNormalizado;
    datosActualizacion.correo = correoNormalizado;
  }

  if (datos.rut !== undefined) {
    const rut = datos.rut?.trim() ? datos.rut.trim() : null;
    if (rut) {
      const rutExistente = await usuarioRepositorio.buscarPorRut(rut);
      if (rutExistente && rutExistente.id !== usuario.id) {
        throw new ErrorHttp(409, 'El RUT ya está registrado');
      }
    }
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

  const usuarioGuardado = await usuarioRepositorio.actualizar(usuario.id, datosActualizacion);

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

  emitirCambioUsuarios();

  return mapearUsuarioPublico(usuarioGuardado);
};
