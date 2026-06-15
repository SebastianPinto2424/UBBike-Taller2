import type { ClientePrisma } from '../../configuracion/prisma';
import { Prisma } from '../../generated/prisma/client';
import * as auditoriaRepositorio from './auditoria.repositorio';

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
  db?: ClientePrisma
): Promise<void> => {
  try {
    await auditoriaRepositorio.crearEvento(
      {
        actorUsuarioId: datos.actorUsuarioId ?? null,
        accion: datos.accion,
        entidad: datos.entidad,
        entidadId: datos.entidadId ?? null,
        ip: datos.ip ?? null,
        userAgent: datos.userAgent ?? null,
        datos: datos.datos as Prisma.InputJsonValue | undefined
      },
      db
    );
  } catch (error) {
    console.error('No se pudo registrar evento de auditoria', error);
  }
};
