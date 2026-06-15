import cors from 'cors';
import helmet from 'helmet';
import express, { Request, Response } from 'express';
import swaggerUi from 'swagger-ui-express';
import { middlewareErrores } from './comun/middlewares/errores.middleware';
import { entorno } from './configuracion/entorno';
import { especificacionSwagger } from './configuracion/swagger';
import { registrarRutasModulos } from './modulos/rutas';

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

registrarRutasModulos(aplicacion);
aplicacion.use(middlewareErrores);

export { aplicacion };
