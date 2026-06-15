import '../helpers/env-setup';
import '../helpers/prisma-mock';
import { prismaMock } from '../helpers/prisma-mock';

jest.mock('../../src/modulos/auditoria/auditoria.servicio', () => ({
  registrarAuditoria: jest.fn().mockResolvedValue(undefined)
}));

jest.mock('../../src/modulos/notificaciones/notificacion.servicio', () => ({
  crearNotificacion: jest.fn().mockResolvedValue(undefined)
}));

import {
  crearUsuarioAdmin,
  eliminarUsuarioAdmin
} from '../../src/modulos/usuarios/usuario.servicio';
import { RolUsuario } from '../../src/modulos/usuarios/rol-usuario';

const usuarioBase = {
  id: 'usuario-1',
  nombre: 'Guardia Prueba',
  correo: 'guardia.externo@correo.cl',
  rut: null,
  rol: RolUsuario.GUARDIA,
  contrasenaHash: '$2a$12$placeholder',
  correoVerificado: true,
  registroParcial: false,
  cuentaActiva: true,
  versionSesion: 0,
  tokenVerificacionCorreo: null,
  tokenVerificacionCorreoExpiraEn: null,
  tokenCambioContrasena: null,
  tokenCambioContrasenaExpiraEn: null,
  eliminadoEn: null,
  creadoEn: new Date(),
  actualizadoEn: new Date()
};

describe('crearUsuarioAdmin', () => {
  it('crea guardias con correo externo y cuenta verificada', async () => {
    prismaMock.usuario.findUnique.mockResolvedValue(null);
    prismaMock.usuario.create.mockResolvedValue(usuarioBase as any);

    const resultado = await crearUsuarioAdmin({
      nombre: usuarioBase.nombre,
      correo: usuarioBase.correo,
      rol: RolUsuario.GUARDIA,
      contrasena: 'Abcdefg1!xyz'
    });

    expect(resultado.correo).toBe(usuarioBase.correo);
    expect(prismaMock.usuario.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          correo: usuarioBase.correo,
          rol: RolUsuario.GUARDIA,
          correoVerificado: true,
          cuentaActiva: true
        })
      })
    );
  });
});

describe('eliminarUsuarioAdmin', () => {
  it('aplica soft-delete e invalida sesiones', async () => {
    prismaMock.usuario.findUnique.mockResolvedValue(usuarioBase as any);
    prismaMock.usuario.count.mockResolvedValue(1);
    prismaMock.usuario.update.mockResolvedValue({
      ...usuarioBase,
      cuentaActiva: false,
      eliminadoEn: new Date(),
      versionSesion: 1
    } as any);

    const resultado = await eliminarUsuarioAdmin(usuarioBase.id, 'admin-1');

    expect(resultado.message).toContain('Cuenta eliminada');
    expect(prismaMock.usuario.update).toHaveBeenCalledWith({
      where: { id: usuarioBase.id },
      data: expect.objectContaining({
        cuentaActiva: false,
        eliminadoEn: expect.any(Date),
        versionSesion: { increment: 1 }
      })
    });
  });

  it('protege contra eliminar el ultimo administrador activo', async () => {
    prismaMock.usuario.findUnique.mockResolvedValue({
      ...usuarioBase,
      rol: RolUsuario.ADMINISTRADOR
    } as any);
    prismaMock.usuario.count.mockResolvedValue(0);

    await expect(eliminarUsuarioAdmin(usuarioBase.id, 'admin-1')).rejects.toMatchObject({
      statusCode: 400
    });
    expect(prismaMock.usuario.update).not.toHaveBeenCalled();
  });
});
