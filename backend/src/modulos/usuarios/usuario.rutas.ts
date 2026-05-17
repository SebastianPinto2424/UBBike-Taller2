import { Router } from 'express';
import { middlewareAutenticacion } from '../../comun/middlewares/autenticacion.middleware';
import { autorizarRoles } from '../../comun/middlewares/autorizar-roles.middleware';
import { validarCuerpo } from '../../comun/middlewares/validar-cuerpo.middleware';
import { actualizarPermisos, listar } from './usuario.controlador';
import { RolUsuario } from './rol-usuario';
import { esquemaActualizarPermisosUsuario } from './usuario.validacion';

const rutasUsuarios = Router();

rutasUsuarios.use(middlewareAutenticacion);
rutasUsuarios.use(autorizarRoles(RolUsuario.ADMINISTRADOR));

rutasUsuarios.get('/', listar);
rutasUsuarios.patch(
  '/:id/permisos',
  validarCuerpo(esquemaActualizarPermisosUsuario),
  actualizarPermisos
);

export { rutasUsuarios };
