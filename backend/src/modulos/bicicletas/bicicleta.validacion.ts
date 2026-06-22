import Joi from 'joi';

export const AROS_BICICLETA = [
  '29',
  '28',
  '27.5',
  '27',
  '26',
  '24',
  '22',
  '20',
  '18',
  '17',
  '16',
  '14',
  '12'
] as const;

export const COLORES_BICICLETA = [
  'Amarillo',
  'Azul',
  'Azul marino',
  'Beige',
  'Blanco',
  'Burdeo',
  'Café',
  'Calipso',
  'Celeste',
  'Champaña',
  'Cian',
  'Cobre',
  'Crema',
  'Dorado',
  'Fucsia',
  'Grafito',
  'Gris',
  'Lila',
  'Magenta',
  'Multicolor',
  'Morado',
  'Mostaza',
  'Naranjo',
  'Negro',
  'Plateado',
  'Rojo',
  'Rosado',
  'Turquesa',
  'Verde',
  'Verde agua',
  'Verde oliva',
  'Violeta'
] as const;

const ALIAS_AROS_BICICLETA: Record<string, string> = {
  '28 1/2': '28',
  '28 x 1 1/2': '28',
  '28 x 1 1/2 (iso 635)': '28',
  '27 (iso 630)': '27',
  '29 / 700c / 28 (iso 622)': '29',
  '700c': '29',
  '28': '28',
  '26 1 1/4': '26',
  '26 x 1 1/4': '26',
  '26 x 1 1/4 (iso 597)': '26',
  '26 1 3/8': '26',
  '26 x 1 3/8': '26',
  '26 x 1 3/8 / 650a (iso 590)': '26',
  '650a': '26',
  '27.5 / 650b (iso 584)': '27.5',
  '650b': '27.5',
  '650c': '27',
  '650c (iso 571)': '27',
  '26 (iso 559)': '26',
  '24 1 1/4': '24',
  '24 x 1 1/4': '24',
  '24 x 1 1/4 (iso 547)': '24',
  '24 1 1/8': '24',
  '24 x 1 1/8': '24',
  '24 x 1 1/8 (iso 540)': '24',
  '24 1': '24',
  '24 x 1': '24',
  '24 x 1 (iso 520)': '24',
  '24 (iso 507)': '24',
  '22 (iso 501)': '22',
  '20 1 1/8': '20',
  '20 x 1 1/8': '20',
  '20 x 1 1/8 (iso 451)': '20',
  '20 (iso 406)': '20',
  '18 (iso 355)': '18',
  '17 (iso 369)': '17',
  '16 1 3/8': '16',
  '16 x 1 3/8': '16',
  '16 x 1 3/8 (iso 349)': '16',
  '16 (iso 305)': '16',
  '14 (iso 254)': '14',
  '12 (iso 203)': '12',
  '12.5': '12'
};

const ALIAS_COLORES_BICICLETA: Record<string, string> = {
  amarillo: 'Amarillo',
  amarilla: 'Amarillo',
  azul: 'Azul',
  marino: 'Azul marino',
  navy: 'Azul marino',
  'azul oscuro': 'Azul marino',
  'azul marino': 'Azul marino',
  beige: 'Beige',
  blanco: 'Blanco',
  blanca: 'Blanco',
  burdeo: 'Burdeo',
  borgona: 'Burdeo',
  borgoña: 'Burdeo',
  vino: 'Burdeo',
  cafe: 'Café',
  marron: 'Café',
  marrón: 'Café',
  calipso: 'Calipso',
  aqua: 'Calipso',
  celeste: 'Celeste',
  champana: 'Champaña',
  champaña: 'Champaña',
  champagne: 'Champaña',
  cian: 'Cian',
  cyan: 'Cian',
  cobre: 'Cobre',
  bronce: 'Cobre',
  crema: 'Crema',
  dorado: 'Dorado',
  dorada: 'Dorado',
  fucsia: 'Fucsia',
  grafito: 'Grafito',
  'gris oscuro': 'Grafito',
  gris: 'Gris',
  plomo: 'Gris',
  lila: 'Lila',
  magenta: 'Magenta',
  multicolor: 'Multicolor',
  morado: 'Morado',
  purpura: 'Morado',
  púrpura: 'Morado',
  mostaza: 'Mostaza',
  naranjo: 'Naranjo',
  naranja: 'Naranjo',
  negro: 'Negro',
  negra: 'Negro',
  plateado: 'Plateado',
  plateada: 'Plateado',
  plata: 'Plateado',
  rojo: 'Rojo',
  roja: 'Rojo',
  rosado: 'Rosado',
  rosada: 'Rosado',
  rosa: 'Rosado',
  turquesa: 'Turquesa',
  verde: 'Verde',
  'verde claro': 'Verde agua',
  'verde agua': 'Verde agua',
  'verde militar': 'Verde oliva',
  'verde oliva': 'Verde oliva',
  violeta: 'Violeta'
};

const PATRON_MARCA_MODELO = /^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9 .&-]+$/;
const PATRON_NUMERO_SERIE = /^[A-Za-z0-9]+(?:-[A-Za-z0-9]+)*$/;

const debeTenerLetra = (valor: string, helpers: Joi.CustomHelpers) =>
  /[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]/.test(valor) ? valor : helpers.error('any.invalid');

const debeTenerLetraONumero = (valor: string, helpers: Joi.CustomHelpers) =>
  /[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9]/.test(valor) ? valor : helpers.error('any.invalid');

const claveCatalogo = (valor: string) =>
  valor
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[“”"']/g, '')
    .replace(/[-–—]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .toLowerCase();

const COLORES_POR_CLAVE = new Map<string, string>([
  ...COLORES_BICICLETA.map((color) => [claveCatalogo(color), color] as const),
  ...Object.entries(ALIAS_COLORES_BICICLETA).map(
    ([alias, color]) => [claveCatalogo(alias), color] as const
  )
]);

const AROS_POR_CLAVE = new Map<string, string>([
  ...AROS_BICICLETA.map((aro) => [claveCatalogo(aro), aro] as const),
  ...Object.entries(ALIAS_AROS_BICICLETA).map(
    ([alias, aro]) => [claveCatalogo(alias), aro] as const
  )
]);

const normalizarColorBicicleta = (valor: string) => {
  const texto = valor.trim();
  if (!texto) {
    return texto;
  }

  const directo = COLORES_POR_CLAVE.get(claveCatalogo(texto));
  if (directo) {
    return directo;
  }

  const partesTexto = texto
    .split(/\s*(?:\/|\+|,|&|\by\b|\be\b)\s*/iu)
    .map((parte) => parte.trim())
    .filter(Boolean);
  const partes = partesTexto.map((parte) => COLORES_POR_CLAVE.get(claveCatalogo(parte)));

  if (partes.length < 2 || partes.length > 3 || partes.some((parte) => !parte)) {
    return null;
  }

  const unicos = [...new Set(partes as string[])];
  return unicos.length >= 2 ? unicos.join(' / ') : null;
};

const normalizarAroBicicleta = (valor: string) => AROS_POR_CLAVE.get(claveCatalogo(valor)) ?? null;

const esquemaFoto = Joi.string()
  .trim()
  .max(7000000)
  .pattern(/^data:image\/(jpeg|jpg|png|webp);base64,[A-Za-z0-9+/=]+$/)
  .allow('', null)
  .messages({
    'string.pattern.base': 'La foto debe ser una imagen valida en formato JPG, PNG o WEBP'
  });

const esquemaDescripcion = Joi.string().trim().min(3).max(100).custom(debeTenerLetra).messages({
  'any.invalid': 'La descripción debe incluir texto, no solo símbolos'
});

const esquemaMarca = Joi.string()
  .trim()
  .min(2)
  .max(40)
  .pattern(PATRON_MARCA_MODELO)
  .custom(debeTenerLetra)
  .allow('', null)
  .messages({
    'any.invalid': 'La marca debe incluir texto identificable',
    'string.pattern.base': 'Solo se permiten letras, números y los signos - . &'
  });

const esquemaModelo = Joi.string()
  .trim()
  .max(40)
  .pattern(PATRON_MARCA_MODELO)
  .custom(debeTenerLetraONumero)
  .allow('', null)
  .messages({
    'any.invalid': 'El modelo debe incluir texto o numeros',
    'string.pattern.base': 'Solo se permiten letras, números y los signos - . &'
  });

const esquemaColor = Joi.string()
  .trim()
  .max(60)
  .custom(
    (valor: string, helpers) => normalizarColorBicicleta(valor) ?? helpers.error('any.invalid')
  )
  .allow('', null)
  .messages({
    'any.invalid': 'Ingresa un color válido',
    'string.max': 'El color no puede superar 60 caracteres'
  });

const esquemaAro = Joi.string()
  .trim()
  .custom((valor: string, helpers) => normalizarAroBicicleta(valor) ?? helpers.error('any.invalid'))
  .allow('', null)
  .messages({
    'any.invalid': 'Selecciona un aro válido de la lista'
  });

const esquemaNumeroSerie = Joi.string()
  .trim()
  .uppercase()
  .min(4)
  .max(40)
  .pattern(PATRON_NUMERO_SERIE)
  .allow('', null)
  .messages({
    'string.pattern.base': 'El número de serie solo admite letras, números y guion'
  });

const esquemaFotoRequerida = Joi.string()
  .trim()
  .max(7000000)
  .pattern(/^data:image\/(jpeg|jpg|png|webp);base64,[A-Za-z0-9+/=]+$/)
  .required()
  .messages({
    'any.required': 'La foto de la bicicleta es obligatoria',
    'string.empty': 'La foto de la bicicleta es obligatoria',
    'string.pattern.base': 'La foto debe ser una imagen valida en formato JPG, PNG o WEBP'
  });

const esquemaMarcaRequerida = Joi.string()
  .trim()
  .min(2)
  .max(40)
  .pattern(PATRON_MARCA_MODELO)
  .custom(debeTenerLetra)
  .required()
  .messages({
    'any.required': 'La marca es obligatoria',
    'string.empty': 'La marca es obligatoria',
    'any.invalid': 'La marca debe incluir texto identificable',
    'string.pattern.base': 'Solo se permiten letras, nÃºmeros y los signos - . &'
  });

const esquemaModeloRequerido = Joi.string()
  .trim()
  .max(40)
  .pattern(PATRON_MARCA_MODELO)
  .custom(debeTenerLetraONumero)
  .required()
  .messages({
    'any.required': 'El modelo es obligatorio',
    'string.empty': 'El modelo es obligatorio',
    'any.invalid': 'El modelo debe incluir texto o numeros',
    'string.pattern.base': 'Solo se permiten letras, nÃºmeros y los signos - . &'
  });

const esquemaColorRequerido = Joi.string()
  .trim()
  .max(60)
  .custom(
    (valor: string, helpers) => normalizarColorBicicleta(valor) ?? helpers.error('any.invalid')
  )
  .required()
  .messages({
    'any.required': 'El color es obligatorio',
    'string.empty': 'El color es obligatorio',
    'any.invalid': 'Ingresa un color vÃ¡lido',
    'string.max': 'El color no puede superar 60 caracteres'
  });

const esquemaAroRequerido = Joi.string()
  .trim()
  .custom((valor: string, helpers) => normalizarAroBicicleta(valor) ?? helpers.error('any.invalid'))
  .required()
  .messages({
    'any.required': 'El aro es obligatorio',
    'string.empty': 'El aro es obligatorio',
    'any.invalid': 'Selecciona un aro vÃ¡lido de la lista'
  });

const esquemaNumeroSerieRequerido = Joi.string()
  .trim()
  .uppercase()
  .min(4)
  .max(40)
  .pattern(PATRON_NUMERO_SERIE)
  .required()
  .messages({
    'any.required': 'El numero de serie es obligatorio',
    'string.empty': 'El numero de serie es obligatorio',
    'string.pattern.base': 'El nÃºmero de serie solo admite letras, nÃºmeros y guion'
  });

export const esquemaDescripcionBicicleta = esquemaDescripcion;
export const esquemaMarcaBicicleta = esquemaMarca;
export const esquemaModeloBicicleta = esquemaModelo;
export const esquemaColorBicicleta = esquemaColor;
export const esquemaAroBicicleta = esquemaAro;
export const esquemaNumeroSerieBicicleta = esquemaNumeroSerie;
export const esquemaFotoBicicleta = esquemaFoto;

export const esquemaCrearBicicleta = Joi.object({
  descripcion: esquemaDescripcion.required(),
  marca: esquemaMarcaRequerida,
  modelo: esquemaModeloRequerido,
  color: esquemaColorRequerido,
  aro: esquemaAroRequerido,
  numeroSerie: esquemaNumeroSerieRequerido,
  fotoUrl: esquemaFotoRequerida,
  activar: Joi.boolean().default(false)
});

export const esquemaActualizarBicicleta = Joi.object({
  descripcion: esquemaDescripcion.optional(),
  marca: esquemaMarca.optional(),
  modelo: esquemaModelo.optional(),
  color: esquemaColor.optional(),
  aro: esquemaAro.optional(),
  numeroSerie: esquemaNumeroSerie.optional(),
  fotoUrl: esquemaFoto.optional()
}).min(1);
