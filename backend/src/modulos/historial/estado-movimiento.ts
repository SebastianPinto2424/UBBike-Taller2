export const EstadoMovimiento = {
  CONFIRMADO: 'CONFIRMADO',
  DENEGADO: 'DENEGADO'
} as const;

export type EstadoMovimiento = (typeof EstadoMovimiento)[keyof typeof EstadoMovimiento];
