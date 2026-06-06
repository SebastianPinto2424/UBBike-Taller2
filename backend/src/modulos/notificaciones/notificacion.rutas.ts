import { Router } from 'express';
import { middlewareAutenticacion } from '../../comun/middlewares/autenticacion.middleware';
import { listarNotificaciones, marcarLeida, marcarTodas } from './notificacion.controlador';

const rutasNotificaciones = Router();

rutasNotificaciones.use(middlewareAutenticacion);
rutasNotificaciones.get('/', listarNotificaciones);
rutasNotificaciones.patch('/leidas', marcarTodas);
rutasNotificaciones.patch('/:id/leida', marcarLeida);

export { rutasNotificaciones };
