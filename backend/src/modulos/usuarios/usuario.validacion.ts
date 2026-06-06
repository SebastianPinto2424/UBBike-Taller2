import Joi from 'joi';
import { RolUsuario } from './rol-usuario';

const rolesGestionables = Object.values(RolUsuario).filter(
  (rol) => rol !== RolUsuario.ADMIN_CENTRAL
);

const validarRut = (valor: string, helpers: Joi.CustomHelpers) => {
  if (valor === '') {
    return valor;
  }

  const limpio = valor.replace(/\./g, '').replace('-', '').toUpperCase();
  const cuerpo = limpio.slice(0, -1);
  const dv = limpio.slice(-1);

  if (!/^\d{7,8}[0-9K]$/.test(limpio)) {
    return helpers.error('any.invalid');
  }

  let suma = 0;
  let multiplicador = 2;

  for (let i = cuerpo.length - 1; i >= 0; i -= 1) {
    suma += Number(cuerpo[i]) * multiplicador;
    multiplicador = multiplicador === 7 ? 2 : multiplicador + 1;
  }

  const esperado = 11 - (suma % 11);
  const dvEsperado = esperado === 11 ? '0' : esperado === 10 ? 'K' : esperado.toString();

  return dv === dvEsperado ? valor : helpers.error('any.invalid');
};

export const esquemaActualizarPermisosUsuario = Joi.object({
  nombre: Joi.string().trim().min(3).max(120).optional(),
  correo: Joi.string().trim().email().max(160).optional(),
  rut: Joi.string().trim().max(20).allow('', null).custom(validarRut).optional().messages({
    'any.invalid': 'El RUT no es válido'
  }),
  rol: Joi.string()
    .valid(...rolesGestionables)
    .optional(),
  cuentaActiva: Joi.boolean().optional(),
  correoVerificado: Joi.boolean().optional()
}).min(1);
