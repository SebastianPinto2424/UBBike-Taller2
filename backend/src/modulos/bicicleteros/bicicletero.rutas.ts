import { Router } from 'express';
import { middlewareAutenticacion } from '../../comun/middlewares/autenticacion.middleware';
import { listar } from './bicicletero.controlador';

const rutasBicicleteros = Router();

rutasBicicleteros.get('/', middlewareAutenticacion, listar);

export { rutasBicicleteros };
