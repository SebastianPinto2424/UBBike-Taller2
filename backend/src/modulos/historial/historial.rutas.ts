import { Router } from 'express';
import { middlewareAutenticacion } from '../../comun/middlewares/autenticacion.middleware';
import { listar, opciones, resumen, exportarExcel } from './historial.controlador';

const rutasHistorial = Router();

rutasHistorial.use(middlewareAutenticacion);
rutasHistorial.get('/exportar-excel', exportarExcel);
rutasHistorial.get('/opciones', opciones);
rutasHistorial.get('/resumen', resumen);
rutasHistorial.get('/', listar);

export { rutasHistorial };
