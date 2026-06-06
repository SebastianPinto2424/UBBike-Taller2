import Joi from 'joi';

export const esquemaSeleccionarBicicleteroGuardia = Joi.object({
  bicicleteroId: Joi.string().uuid().required()
});
