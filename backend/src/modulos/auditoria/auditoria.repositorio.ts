import { Prisma } from '../../generated/prisma/client';
import { prisma, type ClientePrisma } from '../../configuracion/prisma';

type EventoAuditoria = {
  actorUsuarioId: string | null;
  accion: string;
  entidad: string;
  entidadId: string | null;
  ip: string | null;
  userAgent: string | null;
  datos: Prisma.InputJsonValue | undefined;
};

export const crearEvento = (data: EventoAuditoria, client: ClientePrisma = prisma) =>
  client.auditoriaEvento.create({ data });
