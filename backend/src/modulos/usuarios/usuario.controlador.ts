import { controladorAsync } from '../../comun/utils/controlador-async';
import {
  actualizarPermisosUsuario,
  crearUsuarioAdmin,
  eliminarUsuarioAdmin,
  listarUsuarios,
  reenviarCorreoAccesoAdmin,
  reenviarVerificacionCorreoAdmin
} from './usuario.servicio';
import { RolUsuario } from './rol-usuario';

const leerBooleano = (valor: unknown) => {
  if (valor === 'true') {
    return true;
  }
  if (valor === 'false') {
    return false;
  }
  return undefined;
};

const leerRol = (valor: unknown) => {
  if (typeof valor !== 'string') {
    return undefined;
  }

  const normalizado = valor.toUpperCase();
  return Object.values(RolUsuario).includes(normalizado as RolUsuario)
    ? (normalizado as RolUsuario)
    : undefined;
};

export const listar = controladorAsync(async (req, res) => {
  const usuarios = await listarUsuarios({
    q: typeof req.query.q === 'string' ? req.query.q : undefined,
    rol: leerRol(req.query.rol),
    cuentaActiva: leerBooleano(req.query.cuentaActiva),
    correoVerificado: leerBooleano(req.query.correoVerificado)
  });
  return res.status(200).json({ usuarios });
});

export const crear = controladorAsync(async (req, res) => {
  const usuario = await crearUsuarioAdmin(req.body, req.usuario?.usuarioId);
  return res.status(201).json({ usuario });
});

export const actualizarPermisos = controladorAsync(async (req, res) => {
  const usuario = await actualizarPermisosUsuario(req.params.id, req.body, req.usuario?.usuarioId);
  return res.status(200).json({ usuario });
});

export const reenviarVerificacion = controladorAsync(async (req, res) => {
  const resultado = await reenviarVerificacionCorreoAdmin(req.params.id, req.usuario?.usuarioId);
  return res.status(200).json(resultado);
});

export const reenviarAcceso = controladorAsync(async (req, res) => {
  const resultado = await reenviarCorreoAccesoAdmin(req.params.id, req.usuario?.usuarioId);
  return res.status(200).json(resultado);
});

export const eliminar = controladorAsync(async (req, res) => {
  const resultado = await eliminarUsuarioAdmin(req.params.id, req.usuario?.usuarioId);
  return res.status(200).json(resultado);
});
