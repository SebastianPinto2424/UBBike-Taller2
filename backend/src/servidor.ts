import { aplicacion } from './aplicacion';
import { cargarDatosIniciales } from './configuracion/datos-iniciales';
import { entorno } from './configuracion/entorno';
import { prisma } from './configuracion/prisma';

const iniciarServidor = async (): Promise<void> => {
  try {
    await prisma.$connect();
    if (entorno.datosDemo.habilitados) {
      await cargarDatosIniciales();
    }

    const servidor = aplicacion.listen(entorno.puerto, () => {
      console.log(`UBBike backend escuchando en puerto ${entorno.puerto}`);
    });

    const cerrar = async () => {
      servidor.close(async () => {
        await prisma.$disconnect();
        process.exit(0);
      });
    };

    process.on('SIGINT', cerrar);
    process.on('SIGTERM', cerrar);
  } catch (error) {
    console.error('No se pudo iniciar el backend de UBBike', error);
    process.exit(1);
  }
};

void iniciarServidor();
