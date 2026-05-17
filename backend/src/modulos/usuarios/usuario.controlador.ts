import { controladorAsync } from '../../comun/utils/controlador-async';
import { actualizarPermisosUsuario, listarUsuarios } from './usuario.servicio';

export const listar = controladorAsync(async (_req, res) => {
  const usuarios = await listarUsuarios();
  return res.status(200).json({ usuarios });
});

export const actualizarPermisos = controladorAsync(async (req, res) => {
  const usuario = await actualizarPermisosUsuario(req.params.id, req.body, req.usuario?.usuarioId);
  return res.status(200).json({ usuario });
});
