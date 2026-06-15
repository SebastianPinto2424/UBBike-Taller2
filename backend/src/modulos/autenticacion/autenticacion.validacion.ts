import Joi from 'joi';
import { validarRutChileno } from '../../comun/utils/rut';
import { validarNombreCompleto } from '../../comun/utils/nombre';

const mensajeNombre = {
  'any.invalid': 'Ingresa dos nombres y dos apellidos (Nombre Nombre Apellido Apellido)'
};

const mensajeRut = {
  'any.invalid': 'RUT inválido. Usa el formato con guion: xx.xxx.xxx-x'
};

const mensajeCorreoInstitucional = {
  'any.invalid': 'Debes usar un correo @ubiobio.cl o @alumnos.ubiobio.cl'
};

const validarCorreoInstitucional = (valor: string, helpers: Joi.CustomHelpers) => {
  const correo = valor.toLowerCase();
  return correo.endsWith('@ubiobio.cl') || correo.endsWith('@alumnos.ubiobio.cl')
    ? correo
    : helpers.error('any.invalid');
};

const esquemaNombre = Joi.string()
  .trim()
  .max(120)
  .custom(validarNombreCompleto)
  .messages(mensajeNombre);

const esquemaContrasena = Joi.string()
  .min(12)
  .max(72)
  .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).+$/)
  .required()
  .messages({
    'string.min': 'La contraseña debe tener al menos 12 caracteres',
    'string.pattern.base': 'La contraseña debe incluir mayúscula, minúscula, número y símbolo'
  });

const esquemaCorreoInstitucional = Joi.string()
  .trim()
  .lowercase()
  .email()
  .max(160)
  .custom(validarCorreoInstitucional)
  .messages(mensajeCorreoInstitucional);

export const esquemaRegistro = Joi.object({
  nombre: esquemaNombre.required(),
  rut: Joi.string().trim().max(20).custom(validarRutChileno).optional().messages(mensajeRut),
  correo: esquemaCorreoInstitucional.required(),
  contrasena: esquemaContrasena
});

export const esquemaLogin = Joi.object({
  correo: Joi.string().trim().email().required(),
  contrasena: Joi.string().required()
});

export const esquemaSolicitudCambioContrasena = Joi.object({
  correo: esquemaCorreoInstitucional.required()
});

export const esquemaVerificarCorreo = Joi.object({
  token: Joi.string().trim().required()
});

export const esquemaCompletarRegistro = Joi.object({
  token: Joi.string().trim().required(),
  nombre: esquemaNombre.required(),
  contrasena: esquemaContrasena
});

export const esquemaCambioContrasena = Joi.object({
  token: Joi.string().trim().required(),
  contrasena: esquemaContrasena
});

export const esquemaRefreshToken = Joi.object({
  usuarioId: Joi.string().uuid().required(),
  refreshToken: Joi.string().trim().required()
});
