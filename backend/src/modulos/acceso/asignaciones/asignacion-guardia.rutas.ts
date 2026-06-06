import { Router } from 'express';
import { middlewareAutenticacion } from '../../../comun/middlewares/autenticacion.middleware';
import { autorizarRoles } from '../../../comun/middlewares/autorizar-roles.middleware';
import { validarCuerpo } from '../../../comun/middlewares/validar-cuerpo.middleware';
import { RolUsuario } from '../../usuarios/rol-usuario';
import { obtenerMiBicicletero, seleccionarMiBicicletero } from './asignacion-guardia.controlador';
import { esquemaSeleccionarBicicleteroGuardia } from './asignacion-guardia.validacion';

const rutasAsignacionGuardia = Router();

rutasAsignacionGuardia.use(middlewareAutenticacion);
rutasAsignacionGuardia.use(autorizarRoles(RolUsuario.GUARDIA));
rutasAsignacionGuardia.get('/me/bicicletero', obtenerMiBicicletero);
rutasAsignacionGuardia.patch(
  '/me/bicicletero',
  validarCuerpo(esquemaSeleccionarBicicleteroGuardia),
  seleccionarMiBicicletero
);

export { rutasAsignacionGuardia };
