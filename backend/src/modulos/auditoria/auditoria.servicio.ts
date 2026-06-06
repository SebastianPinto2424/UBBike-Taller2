import { prisma, type ClientePrisma } from '../../configuracion/prisma';
import { Prisma } from '../../generated/prisma/client';

type DatosAuditoria = {
  actorUsuarioId?: string | null;
  accion: string;
  entidad: string;
  entidadId?: string | null;
  ip?: string | null;
  userAgent?: string | null;
  datos?: Record<string, unknown> | null;
};

export const registrarAuditoria = async (
  datos: DatosAuditoria,
  db: ClientePrisma = prisma
): Promise<void> => {
  try {
    await db.auditoriaEvento.create({
      data: {
        actorUsuarioId: datos.actorUsuarioId ?? null,
        accion: datos.accion,
        entidad: datos.entidad,
        entidadId: datos.entidadId ?? null,
        ip: datos.ip ?? null,
        userAgent: datos.userAgent ?? null,
        datos: datos.datos as Prisma.InputJsonValue | undefined
      }
    });
  } catch (error) {
    console.error('No se pudo registrar evento de auditoria', error);
  }
};
