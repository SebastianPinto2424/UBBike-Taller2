export const EstadoIncidencia = {
  PENDIENTE: 'PENDIENTE',
  EN_REVISION: 'EN_REVISION',
  RESUELTA: 'RESUELTA',
  DESCARTADA: 'DESCARTADA'
} as const;

export type EstadoIncidencia = (typeof EstadoIncidencia)[keyof typeof EstadoIncidencia];
