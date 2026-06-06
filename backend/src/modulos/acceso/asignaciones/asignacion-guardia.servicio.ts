import { ErrorHttp } from '../../../comun/errors/error-http';
import { prisma } from '../../../configuracion/prisma';
import type { AsignacionGuardia, Bicicletero } from '../../../generated/prisma/client';
import { registrarAuditoria } from '../../auditoria/auditoria.servicio';
import {
  construirStatsBicicletero,
  contarOcupadosBicicletero
} from '../../bicicleteros/bicicletero.ocupacion';
import { crearNotificacion } from '../../notificaciones/notificacion.servicio';
import { TipoNotificacion } from '../../notificaciones/tipo-notificacion';

const mapearBicicletero = async (bicicletero: Bicicletero) => {
  const ocupados = await contarOcupadosBicicletero(bicicletero.id);
  return construirStatsBicicletero(bicicletero, ocupados);
};

const mapearAsignacion = async (asignacion: AsignacionGuardia & { bicicletero: Bicicletero }) => ({
  id: asignacion.id,
  iniciaEn: asignacion.iniciaEn,
  bicicletero: await mapearBicicletero(asignacion.bicicletero)
});

export const obtenerAsignacionActivaGuardia = async (guardiaId: string) => {
  const asignacion = await prisma.asignacionGuardia.findFirst({
    where: {
      guardiaId,
      activa: true
    },
    include: {
      bicicletero: true
    },
    orderBy: {
      iniciaEn: 'desc'
    }
  });

  return asignacion ? mapearAsignacion(asignacion) : null;
};

export const seleccionarBicicleteroGuardia = async (guardiaId: string, bicicleteroId: string) => {
  const resultado = await prisma.$transaction(async (db) => {
    const bicicletero = await db.bicicletero.findFirst({
      where: {
        id: bicicleteroId,
        activo: true
      }
    });

    if (!bicicletero) {
      throw new ErrorHttp(404, 'Bicicletero no encontrado o inactivo');
    }

    const ahora = new Date();

    await db.asignacionGuardia.updateMany({
      where: {
        guardiaId,
        activa: true
      },
      data: {
        activa: false,
        terminaEn: ahora
      }
    });

    const asignacion = await db.asignacionGuardia.create({
      data: {
        guardiaId,
        bicicleteroId: bicicletero.id,
        iniciaEn: ahora,
        terminaEn: null,
        activa: true
      }
    });

    await registrarAuditoria(
      {
        actorUsuarioId: guardiaId,
        accion: 'GUARDIA_BICICLETERO_SELECCIONADO',
        entidad: 'asignaciones_guardias',
        entidadId: asignacion.id,
        datos: {
          bicicleteroId: bicicletero.id
        }
      },
      db
    );

    await crearNotificacion(
      {
        usuarioId: guardiaId,
        titulo: 'Bicicletero asignado',
        mensaje: `Ahora gestionas ${bicicletero.nombre} durante tu turno.`,
        tipo: TipoNotificacion.SISTEMA,
        datos: {
          bicicleteroId: bicicletero.id,
          asignacionId: asignacion.id
        }
      },
      db
    );

    return {
      ...asignacion,
      bicicletero
    };
  });

  return mapearAsignacion(resultado);
};
