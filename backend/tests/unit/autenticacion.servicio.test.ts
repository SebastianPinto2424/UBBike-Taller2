import '../helpers/env-setup';
import '../helpers/prisma-mock';
import { prismaMock } from '../helpers/prisma-mock';

jest.mock('../../src/configuracion/redis', () => ({
  obtenerClienteRedis: jest.fn().mockResolvedValue(null)
}));

jest.mock('../../src/modulos/correos/correo.servicio', () => ({
  crearCorreoVerificacion: jest.fn().mockReturnValue({ asunto: 'Verificar', texto: '', html: '' }),
  crearCorreoCuentaVerificada: jest.fn().mockReturnValue({ asunto: 'Verificada', texto: '', html: '' }),
  crearCorreoCambioContrasena: jest.fn().mockReturnValue({ asunto: 'Cambiar', texto: '', html: '' }),
  crearCorreoContrasenaActualizada: jest.fn().mockReturnValue({ asunto: 'Actualizada', texto: '', html: '' }),
  enviarCorreo: jest.fn().mockResolvedValue(undefined)
}));

jest.mock('../../src/modulos/notificaciones/notificacion.servicio', () => ({
  crearNotificacion: jest.fn().mockResolvedValue(undefined),
  notificarUsuariosPorRol: jest.fn().mockResolvedValue(undefined)
}));

jest.mock('../../src/modulos/auditoria/auditoria.servicio', () => ({
  registrarAuditoria: jest.fn().mockResolvedValue(undefined)
}));

import {
  iniciarSesion,
  registrarUsuario,
  verificarCorreo
} from '../../src/modulos/autenticacion/autenticacion.servicio';

const usuarioBase = {
  id: 'uuid-1',
  nombre: 'Juan Perez',
  correo: 'juan@alumnos.ubiobio.cl',
  rut: '12.345.678-9',
  rol: 'ESTUDIANTE' as const,
  contrasenaHash: '$2a$12$placeholder',
  correoVerificado: false,
  registroParcial: false,
  cuentaActiva: true,
  versionSesion: 0,
  tokenVerificacionCorreo: null,
  tokenVerificacionCorreoExpiraEn: null,
  tokenCambioContrasena: null,
  tokenCambioContrasenaExpiraEn: null,
  creadoEn: new Date(),
  actualizadoEn: new Date()
};

describe('registrarUsuario', () => {
  it('lanza 409 si el correo ya existe', async () => {
    prismaMock.usuario.findUnique.mockResolvedValue(usuarioBase as any);

    await expect(
      registrarUsuario({
        nombre: 'Juan',
        correo: 'juan@alumnos.ubiobio.cl',
        contrasena: 'UBBike2026*Test!'
      })
    ).rejects.toMatchObject({ statusCode: 409 });
  });

  it('crea el usuario si el correo no existe', async () => {
    prismaMock.usuario.findUnique.mockResolvedValue(null);
    prismaMock.usuario.create.mockResolvedValue({
      ...usuarioBase,
      correoVerificado: false
    } as any);

    const resultado = await registrarUsuario({
      nombre: 'Juan',
      correo: 'juan@alumnos.ubiobio.cl',
      contrasena: 'UBBike2026*Test!'
    });

    expect(resultado.message).toContain('Registro recibido');
    expect(prismaMock.usuario.create).toHaveBeenCalled();
  });
});

describe('iniciarSesion', () => {
  it('lanza 401 si el usuario no existe', async () => {
    prismaMock.usuario.findUnique.mockResolvedValue(null);

    await expect(
      iniciarSesion({ correo: 'noexiste@alumnos.ubiobio.cl', contrasena: 'cualquier' })
    ).rejects.toMatchObject({ statusCode: 401 });
  });

  it('lanza 403 si la cuenta esta desactivada', async () => {
    prismaMock.usuario.findUnique.mockResolvedValue({
      ...usuarioBase,
      cuentaActiva: false
    } as any);

    await expect(
      iniciarSesion({ correo: 'juan@alumnos.ubiobio.cl', contrasena: 'cualquier' })
    ).rejects.toMatchObject({ statusCode: 403 });
  });

  it('lanza 403 si el correo no esta verificado', async () => {
    prismaMock.usuario.findUnique.mockResolvedValue({
      ...usuarioBase,
      correoVerificado: false,
      cuentaActiva: true,
      registroParcial: false
    } as any);

    await expect(
      iniciarSesion({ correo: 'juan@alumnos.ubiobio.cl', contrasena: 'cualquier' })
    ).rejects.toMatchObject({ statusCode: 403 });
  });
});

describe('verificarCorreo', () => {
  it('lanza 400 si el token no corresponde a ningun usuario', async () => {
    prismaMock.usuario.findFirst.mockResolvedValue(null);

    await expect(verificarCorreo('token-invalido')).rejects.toMatchObject({ statusCode: 400 });
  });

  it('lanza 400 si el token esta expirado', async () => {
    const fechaPasada = new Date(Date.now() - 1000 * 60 * 60);
    prismaMock.usuario.findFirst.mockResolvedValue({
      ...usuarioBase,
      tokenVerificacionCorreo: 'hash-token',
      tokenVerificacionCorreoExpiraEn: fechaPasada,
      registroParcial: false
    } as any);
    prismaMock.usuario.update.mockResolvedValue(usuarioBase as any);

    await expect(verificarCorreo('token-cualquiera')).rejects.toMatchObject({ statusCode: 400 });
  });
});
