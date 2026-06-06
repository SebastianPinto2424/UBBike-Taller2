export const TipoMovimiento = {
  INGRESO: 'INGRESO',
  RETIRO: 'RETIRO'
} as const;

export type TipoMovimiento = (typeof TipoMovimiento)[keyof typeof TipoMovimiento];
