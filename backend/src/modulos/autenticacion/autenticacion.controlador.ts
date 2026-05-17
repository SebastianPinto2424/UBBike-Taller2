import { SolicitudAutenticada } from '../../comun/middlewares/autenticacion.middleware';
import { controladorAsync } from '../../comun/utils/controlador-async';
import {
  cambiarContrasena as cambiarContrasenaServicio,
  iniciarSesion as iniciarSesionServicio,
  obtenerUsuarioActual,
  registrarUsuario,
  solicitarCambioContrasena as solicitarCambioContrasenaServicio,
  verificarCorreo as verificarCorreoServicio
} from './autenticacion.servicio';

export const registrar = controladorAsync(async (req, res) => {
  const resultado = await registrarUsuario(req.body);
  return res.status(201).json(resultado);
});

export const iniciarSesion = controladorAsync(async (req, res) => {
  const resultado = await iniciarSesionServicio(req.body);
  return res.status(200).json(resultado);
});

export const obtenerPerfil = controladorAsync<SolicitudAutenticada>(async (req, res) => {
  const usuario = await obtenerUsuarioActual(req.usuario!.usuarioId);
  return res.status(200).json({ usuario });
});

export const verificarCorreo = controladorAsync(async (req, res) => {
  const token = String(req.body?.token ?? req.query.token ?? '');
  const resultado = await verificarCorreoServicio(token);
  return res.status(200).json(resultado);
});

export const solicitarCambioContrasena = controladorAsync(async (req, res) => {
  const resultado = await solicitarCambioContrasenaServicio(req.body.correo);
  return res.status(200).json(resultado);
});

export const cambiarContrasena = controladorAsync(async (req, res) => {
  const resultado = await cambiarContrasenaServicio(req.body.token, req.body.contrasena);
  return res.status(200).json(resultado);
});
