import Joi from 'joi';

export const esquemaRegistrarDispositivo = Joi.object({
  token: Joi.string().trim().min(20).max(255).required(),
  plataforma: Joi.string().trim().valid('android', 'ios', 'web').default('android')
});

export const esquemaEliminarDispositivo = Joi.object({
  token: Joi.string().trim().min(20).max(255).required()
});
