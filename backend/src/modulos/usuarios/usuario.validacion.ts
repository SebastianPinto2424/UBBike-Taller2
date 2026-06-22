import Joi from 'joi';
import { RolUsuario } from './rol-usuario';
import { validarRutChileno } from '../../comun/utils/rut';

const esquemaContrasenaAdmin = Joi.string()
  .min(12)
  .max(72)
  .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).+$/)
  .messages({
    'string.min': 'La contraseña debe tener al menos 12 caracteres',
    'string.pattern.base': 'La contraseña debe incluir mayúscula, minúscula, número y símbolo'
  });

export const esquemaCrearUsuario = Joi.object({
  nombre: Joi.string().trim().min(3).max(120).required(),
  correo: Joi.string().trim().email().max(160).required(),
  rut: Joi.string().trim().max(20).allow('', null).custom(validarRutChileno).messages({
    'any.invalid': 'RUT inválido. Usa el formato con guion: xx.xxx.xxx-x'
  }),
  rol: Joi.string()
    .valid(...Object.values(RolUsuario))
    .required(),
  contrasena: esquemaContrasenaAdmin.optional()
});

export const esquemaActualizarPermisosUsuario = Joi.object({
  nombre: Joi.string().trim().min(3).max(120).optional(),
  correo: Joi.string().trim().email().max(160).optional(),
  rut: Joi.string().trim().max(20).allow('', null).custom(validarRutChileno).optional().messages({
    'any.invalid': 'RUT inválido. Usa el formato con guion: xx.xxx.xxx-x'
  }),
  rol: Joi.string()
    .valid(...Object.values(RolUsuario))
    .optional(),
  cuentaActiva: Joi.boolean().optional()
}).min(1);
