import { Router } from 'express';
import { middlewareAutenticacion } from '../../comun/middlewares/autenticacion.middleware';
import { validarCuerpo } from '../../comun/middlewares/validar-cuerpo.middleware';
import {
  activar,
  actualizar,
  crear,
  desactivar,
  eliminar,
  listar,
  obtenerActiva
} from './bicicleta.controlador';
import { esquemaActualizarBicicleta, esquemaCrearBicicleta } from './bicicleta.validacion';

const rutasBicicletas = Router();

rutasBicicletas.use(middlewareAutenticacion);
rutasBicicletas.get('/', listar);
rutasBicicletas.get('/activa', obtenerActiva);
rutasBicicletas.post('/', validarCuerpo(esquemaCrearBicicleta), crear);
rutasBicicletas.patch('/:id', validarCuerpo(esquemaActualizarBicicleta), actualizar);
rutasBicicletas.delete('/:id', eliminar);
rutasBicicletas.patch('/:id/activar', activar);
rutasBicicletas.patch('/:id/desactivar', desactivar);

export { rutasBicicletas };
