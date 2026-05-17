import { Router } from 'express';
import { middlewareAutenticacion } from '../../comun/middlewares/autenticacion.middleware';
import { limitarIntentos } from '../../comun/middlewares/limitador-intentos.middleware';
import { validarCuerpo } from '../../comun/middlewares/validar-cuerpo.middleware';
import {
  cambiarContrasena,
  iniciarSesion,
  obtenerPerfil,
  registrar,
  solicitarCambioContrasena,
  verificarCorreo
} from './autenticacion.controlador';
import {
  esquemaCambioContrasena,
  esquemaLogin,
  esquemaRegistro,
  esquemaSolicitudCambioContrasena,
  esquemaVerificarCorreo
} from './autenticacion.validacion';

const rutasAutenticacion = Router();

rutasAutenticacion.post(
  ['/registro', '/register'],
  limitarIntentos({
    ventanaMs: 15 * 60 * 1000,
    maximo: 20,
    mensaje: 'Demasiados registros desde este origen. Intenta más tarde.'
  }),
  validarCuerpo(esquemaRegistro),
  registrar
);
rutasAutenticacion.post(
  '/login',
  limitarIntentos({
    ventanaMs: 15 * 60 * 1000,
    maximo: 10,
    mensaje: 'Demasiados intentos de ingreso. Intenta más tarde.'
  }),
  validarCuerpo(esquemaLogin),
  iniciarSesion
);
rutasAutenticacion.get(['/perfil', '/me'], middlewareAutenticacion, obtenerPerfil);
rutasAutenticacion.get('/verificar-correo', verificarCorreo);
rutasAutenticacion.post(
  '/verificar-correo',
  validarCuerpo(esquemaVerificarCorreo),
  verificarCorreo
);
rutasAutenticacion.post(
  '/solicitar-cambio-contrasena',
  limitarIntentos({
    ventanaMs: 15 * 60 * 1000,
    maximo: 5,
    mensaje: 'Demasiadas solicitudes de cambio de contraseña. Intenta más tarde.'
  }),
  validarCuerpo(esquemaSolicitudCambioContrasena),
  solicitarCambioContrasena
);
rutasAutenticacion.post(
  '/cambiar-contrasena',
  limitarIntentos({
    ventanaMs: 15 * 60 * 1000,
    maximo: 10,
    mensaje: 'Demasiados intentos de cambio de contraseña. Intenta más tarde.'
  }),
  validarCuerpo(esquemaCambioContrasena),
  cambiarContrasena
);

export { rutasAutenticacion };
