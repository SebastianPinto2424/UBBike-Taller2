import Joi from 'joi';
import { TipoMovimiento } from '../historial/tipo-movimiento';

export const esquemaGenerarQr = Joi.object({
  bicicletaId: Joi.string().uuid().optional(),
  bicicleteroId: Joi.string().uuid().optional(),
  tipo: Joi.string()
    .valid(...Object.values(TipoMovimiento))
    .optional()
});

export const esquemaValidarQr = Joi.object({
  token: Joi.string().trim().required()
});
