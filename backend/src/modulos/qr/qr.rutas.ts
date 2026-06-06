import { Router } from 'express';
import { middlewareAutenticacion } from '../../comun/middlewares/autenticacion.middleware';
import { autorizarRoles } from '../../comun/middlewares/autorizar-roles.middleware';
import { validarCuerpo } from '../../comun/middlewares/validar-cuerpo.middleware';
import { RolUsuario } from '../usuarios/rol-usuario';
import { generar, validar } from './qr.controlador';
import { esquemaGenerarQr, esquemaValidarQr } from './qr.validacion';

const rutasQr = Router();

rutasQr.use(middlewareAutenticacion);
rutasQr.post('/generar', validarCuerpo(esquemaGenerarQr), generar);
rutasQr.post(
  '/validar',
  autorizarRoles(RolUsuario.GUARDIA, RolUsuario.ADMINISTRADOR),
  validarCuerpo(esquemaValidarQr),
  validar
);

export { rutasQr };
