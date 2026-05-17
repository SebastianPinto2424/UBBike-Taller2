import type { Usuario } from '../../generated/prisma/client';

export const mapearUsuarioPublico = (usuario: Usuario) => ({
  id: usuario.id,
  nombre: usuario.nombre,
  correo: usuario.correo,
  rut: usuario.rut,
  rol: usuario.rol,
  correoVerificado: usuario.correoVerificado,
  cuentaActiva: usuario.cuentaActiva,
  creadoEn: usuario.creadoEn,
  actualizadoEn: usuario.actualizadoEn
});
