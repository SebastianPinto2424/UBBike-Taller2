export const TipoIncidencia = {
  PROBLEMA_QR: 'PROBLEMA_QR',
  DANO_BICICLETA: 'DANO_BICICLETA',
  DANO_INFRAESTRUCTURA: 'DANO_INFRAESTRUCTURA',
  PROBLEMA_MOVIMIENTO: 'PROBLEMA_MOVIMIENTO',
  USUARIO_DATOS: 'USUARIO_DATOS',
  OTRO: 'OTRO'
} as const;

export type TipoIncidencia = (typeof TipoIncidencia)[keyof typeof TipoIncidencia];
