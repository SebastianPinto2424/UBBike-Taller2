import bcrypt from 'bcryptjs';
import { ErrorHttp } from '../../comun/errors/error-http';
import { entorno } from '../../configuracion/entorno';
import * as usuarioRepositorio from './usuario.repositorio';
import { registrarAuditoria } from '../auditoria/auditoria.servicio';
import {
  crearCorreoCuentaAdministrativa,
  crearCorreoCuentaDesactivada,
  crearCorreoCuentaReactivada,
  crearCorreoRolActualizado,
  crearCorreoVerificacion,
  enviarCorreo
} from '../correos/correo.servicio';
import { crearNotificacion } from '../notificaciones/notificacion.servicio';
import { TipoNotificacion } from '../notificaciones/tipo-notificacion';
import { mapearUsuarioPublico } from './usuario.mapeador';
import { RolUsuario } from './rol-usuario';
import { EventosTiempoReal, emitirTiempoReal, salaRol } from '../../tiempo-real/tiempo-real';
import {
  crearTokenSeguro,
  hashearToken,
  horasExpiracionVerificacionCorreo
} from '../autenticacion/autenticacion.tokens';

const emitirCambioUsuarios = () =>
  emitirTiempoReal([salaRol(RolUsuario.ADMINISTRADOR)], EventosTiempoReal.USUARIO);

const crearDatosInvitacionAcceso = () => {
  const tokenCambioContrasena = crearTokenSeguro();
  const tokenCambioContrasenaHash = hashearToken(tokenCambioContrasena);
  const tokenCambioContrasenaExpiraEn = new Date(
    Date.now() + 1000 * 60 * 60 * horasExpiracionVerificacionCorreo
  );
  const enlaceDefinirContrasena = `${entorno.app.urlFrontend}/cambiar-contrasena?token=${tokenCambioContrasena}`;

  return {
    tokenCambioContrasenaHash,
    tokenCambioContrasenaExpiraEn,
    enlaceDefinirContrasena
  };
};

type DatosCrearUsuario = {
  nombre: string;
  correo: string;
  rut?: string | null;
  rol: RolUsuario;
  contrasena?: string | null;
};

type DatosActualizarPermisos = {
  nombre?: string;
  correo?: string;
  rut?: string | null;
  rol?: RolUsuario;
  cuentaActiva?: boolean;
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

  const porCorreo = await usuarioRepositorio.buscarPorCorreo(correoNormalizado);
  const porRut = rut ? await usuarioRepositorio.buscarPorRut(rut) : null;

  if (porCorreo && !porCorreo.eliminadoEn) {
    throw new ErrorHttp(409, 'El correo ya está registrado');
  }
  if (porRut && !porRut.eliminadoEn) {
    throw new ErrorHttp(409, 'El RUT ya está registrado');
  }

  const { tokenCambioContrasenaHash, tokenCambioContrasenaExpiraEn, enlaceDefinirContrasena } =
    crearDatosInvitacionAcceso();
  const contrasenaHash = await bcrypt.hash(crearTokenSeguro(), 12);

  if (porCorreo?.eliminadoEn && porRut?.eliminadoEn && porCorreo.id !== porRut.id) {
    throw new ErrorHttp(
      409,
      'El correo y el RUT pertenecen a cuentas eliminadas distintas. Revisa el caso antes de reactivar.'
    );
  }

  const cuentaEliminada = porRut?.eliminadoEn ? porRut : porCorreo?.eliminadoEn ? porCorreo : null;
  if (cuentaEliminada) {
    const usuarioRestaurado = await usuarioRepositorio.actualizar(cuentaEliminada.id, {
      nombre: datos.nombre.trim(),
      correo: correoNormalizado,
      rut,
      rol: datos.rol,
      contrasenaHash,
      correoVerificado: false,
      registroParcial: false,
      debeCambiarContrasena: true,
      cuentaActiva: true,
      eliminadoEn: null,
      tokenVerificacionCorreo: null,
      tokenVerificacionCorreoExpiraEn: null,
      tokenCambioContrasena: tokenCambioContrasenaHash,
      tokenCambioContrasenaExpiraEn,
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

    const correoInvitacion = crearCorreoCuentaAdministrativa(
      usuarioRestaurado.nombre,
      enlaceDefinirContrasena,
      horasExpiracionVerificacionCorreo
    );
    await enviarCorreo({
      para: usuarioRestaurado.correo,
      asunto: correoInvitacion.asunto,
      texto: correoInvitacion.texto,
      html: correoInvitacion.html
    });

    await registrarAuditoria({
      actorUsuarioId: actorUsuarioId ?? null,
      accion: 'USUARIO_RESTAURADO_ADMIN',
      entidad: 'usuarios',
      entidadId: usuarioRestaurado.id,
      datos: {
        correo: usuarioRestaurado.correo,
        rol: usuarioRestaurado.rol,
        invitacionCorreo: true
      }
    });

    emitirCambioUsuarios();

    return mapearUsuarioPublico(usuarioRestaurado);
  }

  const usuarioGuardado = await usuarioRepositorio.crear({
    nombre: datos.nombre.trim(),
    correo: correoNormalizado,
    rut,
    rol: datos.rol,
    contrasenaHash,
    correoVerificado: false,
    registroParcial: false,
    debeCambiarContrasena: true,
    cuentaActiva: true,
    tokenCambioContrasena: tokenCambioContrasenaHash,
    tokenCambioContrasenaExpiraEn
  });

  await crearNotificacion({
    usuarioId: usuarioGuardado.id,
    titulo: 'Cuenta creada',
    mensaje: 'Administracion creo tu cuenta UBBike. Revisa tu correo para definir la contrasena.',
    tipo: TipoNotificacion.CUENTA,
    datos: {
      rol: usuarioGuardado.rol,
      cuentaActiva: usuarioGuardado.cuentaActiva,
      correoVerificado: usuarioGuardado.correoVerificado
    }
  });

  const correoInvitacion = crearCorreoCuentaAdministrativa(
    usuarioGuardado.nombre,
    enlaceDefinirContrasena,
    horasExpiracionVerificacionCorreo
  );
  await enviarCorreo({
    para: usuarioGuardado.correo,
    asunto: correoInvitacion.asunto,
    texto: correoInvitacion.texto,
    html: correoInvitacion.html
  });

  await registrarAuditoria({
    actorUsuarioId: actorUsuarioId ?? null,
    accion: 'USUARIO_CREADO_ADMIN',
    entidad: 'usuarios',
    entidadId: usuarioGuardado.id,
    datos: {
      correo: usuarioGuardado.correo,
      rol: usuarioGuardado.rol,
      invitacionCorreo: true
    }
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

  const correoCuentaDesactivada = crearCorreoCuentaDesactivada(usuarioGuardado.nombre);
  await enviarCorreo({
    para: usuarioGuardado.correo,
    asunto: correoCuentaDesactivada.asunto,
    texto: correoCuentaDesactivada.texto,
    html: correoCuentaDesactivada.html
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

export const reenviarVerificacionCorreoAdmin = async (
  usuarioId: string,
  actorUsuarioId?: string
) => {
  const usuario = await usuarioRepositorio.buscarPorId(usuarioId);

  if (!usuario) {
    throw new ErrorHttp(404, 'Usuario no encontrado');
  }
  if (usuario.eliminadoEn) {
    throw new ErrorHttp(409, 'No puedes reenviar verificacion a una cuenta eliminada');
  }
  if (usuario.correoVerificado) {
    throw new ErrorHttp(409, 'El correo ya esta verificado');
  }
  if (usuario.debeCambiarContrasena) {
    throw new ErrorHttp(409, 'Reenvia el correo de acceso para esta cuenta');
  }

  const tokenVerificacion = crearTokenSeguro();
  const tokenVerificacionCorreo = hashearToken(tokenVerificacion);
  const tokenVerificacionCorreoExpiraEn = new Date(
    Date.now() + 1000 * 60 * 60 * horasExpiracionVerificacionCorreo
  );

  const usuarioActualizado = await usuarioRepositorio.actualizar(usuario.id, {
    tokenVerificacionCorreo,
    tokenVerificacionCorreoExpiraEn
  });

  const enlace = `${entorno.app.urlFrontend}/verificar-correo?token=${tokenVerificacion}`;
  const correo = crearCorreoVerificacion(usuarioActualizado.nombre, enlace);
  await enviarCorreo({
    para: usuarioActualizado.correo,
    asunto: correo.asunto,
    texto: correo.texto,
    html: correo.html
  });

  await registrarAuditoria({
    actorUsuarioId: actorUsuarioId ?? null,
    accion: 'CORREO_VERIFICACION_REENVIADO_ADMIN',
    entidad: 'usuarios',
    entidadId: usuarioActualizado.id,
    datos: {
      correo: usuarioActualizado.correo
    }
  });

  return { message: 'Correo de verificacion reenviado' };
};

export const reenviarCorreoAccesoAdmin = async (usuarioId: string, actorUsuarioId?: string) => {
  const usuario = await usuarioRepositorio.buscarPorId(usuarioId);

  if (!usuario) {
    throw new ErrorHttp(404, 'Usuario no encontrado');
  }
  if (usuario.eliminadoEn) {
    throw new ErrorHttp(409, 'No puedes reenviar acceso a una cuenta eliminada');
  }
  if (!usuario.cuentaActiva) {
    throw new ErrorHttp(409, 'Reactiva el acceso antes de reenviar el correo');
  }
  if (!usuario.debeCambiarContrasena) {
    throw new ErrorHttp(409, 'La cuenta ya tiene su contrasena configurada');
  }

  const { tokenCambioContrasenaHash, tokenCambioContrasenaExpiraEn, enlaceDefinirContrasena } =
    crearDatosInvitacionAcceso();

  const usuarioActualizado = await usuarioRepositorio.actualizar(usuario.id, {
    tokenCambioContrasena: tokenCambioContrasenaHash,
    tokenCambioContrasenaExpiraEn
  });

  const correoInvitacion = crearCorreoCuentaAdministrativa(
    usuarioActualizado.nombre,
    enlaceDefinirContrasena,
    horasExpiracionVerificacionCorreo
  );
  await enviarCorreo({
    para: usuarioActualizado.correo,
    asunto: correoInvitacion.asunto,
    texto: correoInvitacion.texto,
    html: correoInvitacion.html
  });

  await registrarAuditoria({
    actorUsuarioId: actorUsuarioId ?? null,
    accion: 'CORREO_ACCESO_REENVIADO_ADMIN',
    entidad: 'usuarios',
    entidadId: usuarioActualizado.id,
    datos: {
      correo: usuarioActualizado.correo,
      rol: usuarioActualizado.rol
    }
  });

  return { message: 'Correo de acceso reenviado' };
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

  const correoCambia =
    datos.correo !== undefined && usuario.correo !== datos.correo.trim().toLowerCase();
  const rolCambia = datos.rol !== undefined && usuario.rol !== datos.rol;
  const cuentaActivaCambia =
    datos.cuentaActiva !== undefined && usuario.cuentaActiva !== datos.cuentaActiva;
  const dejaDeSerAdministradorActivo =
    usuario.rol === RolUsuario.ADMINISTRADOR &&
    ((datos.rol !== undefined && datos.rol !== RolUsuario.ADMINISTRADOR) ||
      datos.cuentaActiva === false ||
      correoCambia);

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
    tokenCambioContrasena?: string | null;
    tokenCambioContrasenaExpiraEn?: Date | null;
    versionSesion?: {
      increment: number;
    };
  } = {};

  let correoVerificacionPendiente:
    | {
        token: string;
      }
    | undefined;
  let correoAccesoPendiente:
    | {
        enlace: string;
      }
    | undefined;

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
    if (usuario.correo !== correoNormalizado) {
      datosActualizacion.correoVerificado = false;
      datosActualizacion.tokenVerificacionCorreo = null;
      datosActualizacion.tokenVerificacionCorreoExpiraEn = null;

      if (usuario.debeCambiarContrasena) {
        const {
          tokenCambioContrasenaHash,
          tokenCambioContrasenaExpiraEn,
          enlaceDefinirContrasena
        } = crearDatosInvitacionAcceso();
        datosActualizacion.tokenCambioContrasena = tokenCambioContrasenaHash;
        datosActualizacion.tokenCambioContrasenaExpiraEn = tokenCambioContrasenaExpiraEn;
        correoAccesoPendiente = {
          enlace: enlaceDefinirContrasena
        };
      } else {
        const tokenVerificacion = crearTokenSeguro();
        datosActualizacion.tokenVerificacionCorreo = hashearToken(tokenVerificacion);
        datosActualizacion.tokenVerificacionCorreoExpiraEn = new Date(
          Date.now() + 1000 * 60 * 60 * horasExpiracionVerificacionCorreo
        );
        correoVerificacionPendiente = {
          token: tokenVerificacion
        };
      }
    }
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

  if (invalidarSesiones) {
    datosActualizacion.versionSesion = {
      increment: 1
    };
  }

  const usuarioGuardado = await usuarioRepositorio.actualizar(usuario.id, datosActualizacion);

  if (correoAccesoPendiente) {
    const correoInvitacion = crearCorreoCuentaAdministrativa(
      usuarioGuardado.nombre,
      correoAccesoPendiente.enlace,
      horasExpiracionVerificacionCorreo
    );
    await enviarCorreo({
      para: usuarioGuardado.correo,
      asunto: correoInvitacion.asunto,
      texto: correoInvitacion.texto,
      html: correoInvitacion.html
    });
  }

  if (correoVerificacionPendiente) {
    const enlace = `${entorno.app.urlFrontend}/verificar-correo?token=${correoVerificacionPendiente.token}`;
    const correo = crearCorreoVerificacion(usuarioGuardado.nombre, enlace);
    await enviarCorreo({
      para: usuarioGuardado.correo,
      asunto: correo.asunto,
      texto: correo.texto,
      html: correo.html
    });
  }

  if (cuentaActivaCambia) {
    const correoCuenta = usuarioGuardado.cuentaActiva
      ? crearCorreoCuentaReactivada(usuarioGuardado.nombre)
      : crearCorreoCuentaDesactivada(usuarioGuardado.nombre);

    await enviarCorreo({
      para: usuarioGuardado.correo,
      asunto: correoCuenta.asunto,
      texto: correoCuenta.texto,
      html: correoCuenta.html
    });
  }

  if (rolCambia) {
    const correoRol = crearCorreoRolActualizado(
      usuarioGuardado.nombre,
      usuario.rol,
      usuarioGuardado.rol
    );

    await enviarCorreo({
      para: usuarioGuardado.correo,
      asunto: correoRol.asunto,
      texto: correoRol.texto,
      html: correoRol.html
    });
  }

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
