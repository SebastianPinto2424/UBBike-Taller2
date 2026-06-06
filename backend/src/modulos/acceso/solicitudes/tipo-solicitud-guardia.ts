export const TipoSolicitudGuardia = {
  GUARDIA_AUSENTE: 'GUARDIA_AUSENTE',
  REQUIERE_SERVICIO: 'REQUIERE_SERVICIO'
} as const;

export type TipoSolicitudGuardia = (typeof TipoSolicitudGuardia)[keyof typeof TipoSolicitudGuardia];
