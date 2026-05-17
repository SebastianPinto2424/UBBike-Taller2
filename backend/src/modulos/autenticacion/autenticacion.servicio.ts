import bcrypt from 'bcryptjs';
import { ErrorHttp } from '../../comun/errors/error-http';
import { entorno } from '../../configuracion/entorno';
import { prisma } from '../../configuracion/prisma';
import {
  crearCorreoCambioContrasena,
  crearCorreoContrasenaActualizada,
  crearCorreoCuentaVerificada,
  crearCorreoVerificacion,
  enviarCorreo
} from '../correos/correo.servicio';
import { mapearUsuarioPublico } from '../usuarios/usuario.mapeador';
import {
  crearTokenSeguro,
  crearTokenSesion,
  hashearToken,
  horasExpiracionVerificacionCorreo,
  resolverRolRegistrable
} from './autenticacion.tokens';

type DatosRegistro = {
  nombre: string;
  rut?: string;
  correo: string;
  contrasena: string;
};

type DatosLogin = {
  correo: string;
  contrasena: string;
};

export const registrarUsuario = async (datos: DatosRegistro) => {
  const correoNormalizado = datos.correo.toLowerCase();
  const rolAsignado = resolverRolRegistrable(correoNormalizado);
  const usuarioExistente = await prisma.usuario.findUnique({
    where: {
      correo: correoNormalizado
    }
  });

  if (usuarioExistente) {
    throw new ErrorHttp(409, 'El correo ya está registrado');
  }

  if (datos.rut) {
    const rutExistente = await prisma.usuario.findUnique({
      where: {
        rut: datos.rut
      }
    });

    if (rutExistente) {
      throw new ErrorHttp(409, 'El RUT ya está registrado');
    }
  }

  const contrasenaHash = await bcrypt.hash(datos.contrasena, 12);
  const tokenVerificacion = crearTokenSeguro();
  const usuarioGuardado = await prisma.usuario.create({
    data: {
      nombre: datos.nombre,
      correo: correoNormalizado,
      rut: datos.rut ?? null,
      rol: rolAsignado,
      contrasenaHash,
      cuentaActiva: true,
      correoVerificado: false,
      tokenVerificacionCorreo: hashearToken(tokenVerificacion),
      tokenVerificacionCorreoExpiraEn: new Date(
        Date.now() + 1000 * 60 * 60 * horasExpiracionVerificacionCorreo
      )
    }
  });
  const enlace = `${entorno.app.urlFrontend}/#/verificar-correo?token=${tokenVerificacion}`;
  const correo = crearCorreoVerificacion(usuarioGuardado.nombre, enlace);

  await enviarCorreo({
    para: usuarioGuardado.correo,
    asunto: correo.asunto,
    texto: correo.texto,
    html: correo.html
  });

  return {
    message: 'Registro recibido. Revisa tu correo para activar la cuenta.',
    usuario: mapearUsuarioPublico(usuarioGuardado)
  };
};

export const iniciarSesion = async (datos: DatosLogin) => {
  const usuario = await prisma.usuario.findUnique({
    where: {
      correo: datos.correo.toLowerCase()
    }
  });

  if (!usuario) {
    throw new ErrorHttp(401, 'Credenciales inválidas');
  }

  if (!usuario.cuentaActiva) {
    throw new ErrorHttp(403, 'La cuenta está desactivada');
  }

  if (!usuario.correoVerificado) {
    throw new ErrorHttp(403, 'Debes verificar tu correo antes de iniciar sesión');
  }

  const contrasenaCoincide = await bcrypt.compare(datos.contrasena, usuario.contrasenaHash);

  if (!contrasenaCoincide) {
    throw new ErrorHttp(401, 'Credenciales inválidas');
  }

  return {
    usuario: mapearUsuarioPublico(usuario),
    token: crearTokenSesion(usuario.id, usuario.rol, usuario.versionSesion)
  };
};

export const obtenerUsuarioActual = async (usuarioId: string) => {
  const usuario = await prisma.usuario.findUnique({
    where: {
      id: usuarioId
    }
  });

  if (!usuario) {
    throw new ErrorHttp(404, 'Usuario no encontrado');
  }

  return mapearUsuarioPublico(usuario);
};

export const verificarCorreo = async (token: string) => {
  const usuario = await prisma.usuario.findFirst({
    where: {
      tokenVerificacionCorreo: hashearToken(token)
    }
  });

  if (!usuario) {
    throw new ErrorHttp(400, 'Token de verificación inválido');
  }

  if (
    !usuario.tokenVerificacionCorreoExpiraEn ||
    usuario.tokenVerificacionCorreoExpiraEn.getTime() < Date.now()
  ) {
    await prisma.usuario.update({
      where: {
        id: usuario.id
      },
      data: {
        tokenVerificacionCorreo: null,
        tokenVerificacionCorreoExpiraEn: null
      }
    });
    throw new ErrorHttp(400, 'Token de verificación expirado. Solicita un nuevo registro.');
  }

  const usuarioGuardado = await prisma.usuario.update({
    where: {
      id: usuario.id
    },
    data: {
      correoVerificado: true,
      tokenVerificacionCorreo: null,
      tokenVerificacionCorreoExpiraEn: null
    }
  });

  const correoCuentaVerificada = crearCorreoCuentaVerificada(usuarioGuardado.nombre);
  await enviarCorreo({
    para: usuarioGuardado.correo,
    asunto: correoCuentaVerificada.asunto,
    texto: correoCuentaVerificada.texto,
    html: correoCuentaVerificada.html
  });

  return {
    message: 'Correo verificado correctamente',
    usuario: mapearUsuarioPublico(usuarioGuardado)
  };
};

export const solicitarCambioContrasena = async (correo: string) => {
  const usuario = await prisma.usuario.findUnique({
    where: {
      correo: correo.toLowerCase()
    }
  });

  if (!usuario) {
    return {
      message: 'Si el correo existe, enviaremos instrucciones de recuperacion.'
    };
  }

  const tokenCambioContrasena = crearTokenSeguro();
  const usuarioActualizado = await prisma.usuario.update({
    where: {
      id: usuario.id
    },
    data: {
      tokenCambioContrasena: hashearToken(tokenCambioContrasena),
      tokenCambioContrasenaExpiraEn: new Date(Date.now() + 1000 * 60 * 30)
    }
  });

  const enlace = `${entorno.app.urlFrontend}/#/cambiar-contrasena?token=${tokenCambioContrasena}`;
  const correoCambio = crearCorreoCambioContrasena(usuarioActualizado.nombre, enlace);

  await enviarCorreo({
    para: usuarioActualizado.correo,
    asunto: correoCambio.asunto,
    texto: correoCambio.texto,
    html: correoCambio.html
  });

  return {
    message: 'Si el correo existe, enviaremos instrucciones de recuperacion.'
  };
};

export const cambiarContrasena = async (token: string, contrasena: string) => {
  const usuario = await prisma.usuario.findFirst({
    where: {
      tokenCambioContrasena: hashearToken(token)
    }
  });

  if (!usuario || !usuario.tokenCambioContrasenaExpiraEn) {
    throw new ErrorHttp(400, 'Token de cambio de contraseña inválido');
  }

  if (usuario.tokenCambioContrasenaExpiraEn.getTime() < Date.now()) {
    throw new ErrorHttp(400, 'Token de cambio de contraseña expirado');
  }

  await prisma.usuario.update({
    where: {
      id: usuario.id
    },
    data: {
      contrasenaHash: await bcrypt.hash(contrasena, 12),
      tokenCambioContrasena: null,
      tokenCambioContrasenaExpiraEn: null,
      versionSesion: {
        increment: 1
      }
    }
  });

  const correoContrasenaActualizada = crearCorreoContrasenaActualizada(usuario.nombre);
  await enviarCorreo({
    para: usuario.correo,
    asunto: correoContrasenaActualizada.asunto,
    texto: correoContrasenaActualizada.texto,
    html: correoContrasenaActualizada.html
  });

  return {
    message: 'Contrasena actualizada correctamente'
  };
};
