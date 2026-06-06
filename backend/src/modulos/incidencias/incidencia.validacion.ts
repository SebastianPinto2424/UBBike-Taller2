import Joi from 'joi';
import { EstadoIncidencia } from './estado-incidencia';
import { TipoIncidencia } from './tipo-incidencia';

export const esquemaCrearIncidencia = Joi.object({
  bicicleteroId: Joi.string().uuid().required(),
  bicicletaId: Joi.string().uuid().allow('', null),
  tipo: Joi.string()
    .valid(...Object.values(TipoIncidencia))
    .default(TipoIncidencia.OTRO),
  descripcion: Joi.string().trim().min(8).max(1000).required()
});

export const esquemaActualizarEstadoIncidencia = Joi.object({
  estado: Joi.string()
    .valid(...Object.values(EstadoIncidencia))
    .required(),
  respuesta: Joi.when('estado', {
    is: Joi.valid(EstadoIncidencia.RESUELTA, EstadoIncidencia.DESCARTADA),
    then: Joi.string().trim().min(8).max(1000).required().messages({
      'any.required': 'Debes indicar una respuesta para cerrar la incidencia',
      'string.empty': 'Debes indicar una respuesta para cerrar la incidencia',
      'string.min': 'La respuesta debe explicar la resolución con al menos 8 caracteres'
    }),
    otherwise: Joi.string().trim().max(1000).allow('', null).optional()
  })
});
