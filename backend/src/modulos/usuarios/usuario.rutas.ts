import { Router } from 'express';
import { middlewareAutenticacion } from '../../comun/middlewares/autenticacion.middleware';
import { autorizarRoles } from '../../comun/middlewares/autorizar-roles.middleware';
import { validarCuerpo } from '../../comun/middlewares/validar-cuerpo.middleware';
import { actualizarPermisos, crear, eliminar, listar } from './usuario.controlador';
import { RolUsuario } from './rol-usuario';
import { esquemaActualizarPermisosUsuario, esquemaCrearUsuario } from './usuario.validacion';

const rutasUsuarios = Router();

rutasUsuarios.use(middlewareAutenticacion);
rutasUsuarios.use(autorizarRoles(RolUsuario.ADMINISTRADOR));

rutasUsuarios.get('/', listar);
rutasUsuarios.post('/', validarCuerpo(esquemaCrearUsuario), crear);
rutasUsuarios.patch(
  '/:id/permisos',
  validarCuerpo(esquemaActualizarPermisosUsuario),
  actualizarPermisos
);
rutasUsuarios.delete('/:id', eliminar);

export { rutasUsuarios };
