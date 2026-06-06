import cors from 'cors';
import helmet from 'helmet';
import express, { Request, Response } from 'express';
import swaggerUi from 'swagger-ui-express';
import { rutasAutenticacion } from './modulos/autenticacion/autenticacion.rutas';
import { rutasBicicletas } from './modulos/bicicletas/bicicleta.rutas';
import { rutasBicicleteros } from './modulos/bicicleteros/bicicletero.rutas';
import { rutasHistorial } from './modulos/historial/historial.rutas';
import { rutasNotificaciones } from './modulos/notificaciones/notificacion.rutas';
import { rutasQr } from './modulos/qr/qr.rutas';
import { rutasAcceso } from './modulos/acceso/operaciones/acceso.rutas';
import { rutasAsignacionGuardia } from './modulos/acceso/asignaciones/asignacion-guardia.rutas';
import { rutasSolicitudesGuardia } from './modulos/acceso/solicitudes/solicitud-guardia.rutas';
import { rutasIncidencias } from './modulos/incidencias/incidencia.rutas';
import { rutasUsuarios } from './modulos/usuarios/usuario.rutas';
import { middlewareErrores } from './comun/middlewares/errores.middleware';
import { entorno } from './configuracion/entorno';
import { especificacionSwagger } from './configuracion/swagger';

const aplicacion = express();

aplicacion.set('trust proxy', entorno.servidor.trustProxy);
aplicacion.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
aplicacion.use(
  cors({
    origin: (origen, callback) => {
      if (!origen || entorno.cors.origenes.includes(origen)) {
        return callback(null, true);
      }

      return callback(null, false);
    }
  })
);
aplicacion.use(express.json({ limit: '8mb' }));
aplicacion.use(
  entorno.archivos.rutaPublicaUploads,
  express.static(entorno.archivos.directorioUploads, {
    index: false,
    fallthrough: false,
    maxAge: '7d'
  })
);

if (entorno.swagger.habilitado) {
  aplicacion.use(
    '/docs',
    swaggerUi.serve,
    swaggerUi.setup(especificacionSwagger, {
      customSiteTitle: 'UBBike API Docs',
      swaggerOptions: { persistAuthorization: true }
    })
  );

  aplicacion.get('/docs.json', (_req: Request, res: Response) => {
    return res.json(especificacionSwagger);
  });
}

aplicacion.get(['/salud', '/health'], (_req: Request, res: Response) => {
  return res.status(200).json({
    status: 'ok',
    message: 'UBBike backend funcionando'
  });
});

aplicacion.use('/autenticacion', rutasAutenticacion);
aplicacion.use('/auth', rutasAutenticacion);
aplicacion.use('/bicicletas', rutasBicicletas);
aplicacion.use('/bicicleteros', rutasBicicleteros);
aplicacion.use('/historial', rutasHistorial);
aplicacion.use('/notificaciones', rutasNotificaciones);
aplicacion.use('/qr', rutasQr);
aplicacion.use('/accesos', rutasAcceso);
aplicacion.use('/guardias', rutasAsignacionGuardia);
aplicacion.use('/solicitudes-guardia', rutasSolicitudesGuardia);
aplicacion.use('/incidencias', rutasIncidencias);
aplicacion.use('/usuarios', rutasUsuarios);
aplicacion.use(middlewareErrores);

export { aplicacion };
