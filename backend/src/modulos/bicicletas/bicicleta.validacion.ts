import Joi from 'joi';

const esquemaFoto = Joi.string()
  .trim()
  .max(7000000)
  .pattern(/^data:image\/(jpeg|jpg|png|webp);base64,[A-Za-z0-9+/=]+$/)
  .allow('', null)
  .messages({
    'string.pattern.base': 'La foto debe ser una imagen valida en formato JPG, PNG o WEBP'
  });

export const esquemaCrearBicicleta = Joi.object({
  descripcion: Joi.string().trim().min(3).max(255).required(),
  marca: Joi.string().trim().max(80).allow('', null),
  modelo: Joi.string().trim().max(80).allow('', null),
  color: Joi.string().trim().max(60).allow('', null),
  aro: Joi.string().trim().max(30).allow('', null),
  numeroSerie: Joi.string().trim().max(120).allow('', null),
  fotoUrl: esquemaFoto,
  activar: Joi.boolean().default(false)
});

export const esquemaActualizarBicicleta = Joi.object({
  descripcion: Joi.string().trim().min(3).max(255).optional(),
  marca: Joi.string().trim().max(80).allow('', null).optional(),
  modelo: Joi.string().trim().max(80).allow('', null).optional(),
  color: Joi.string().trim().max(60).allow('', null).optional(),
  aro: Joi.string().trim().max(30).allow('', null).optional(),
  numeroSerie: Joi.string().trim().max(120).allow('', null).optional(),
  fotoUrl: esquemaFoto.optional()
}).min(1);
