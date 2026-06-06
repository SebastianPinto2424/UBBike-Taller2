export const EstadoSolicitudGuardia = {
  PENDIENTE: 'PENDIENTE',
  NOTIFICADA: 'NOTIFICADA',
  EN_CAMINO: 'EN_CAMINO',
  RESUELTA: 'RESUELTA',
  CANCELADA: 'CANCELADA'
} as const;

export type EstadoSolicitudGuardia =
  (typeof EstadoSolicitudGuardia)[keyof typeof EstadoSolicitudGuardia];
