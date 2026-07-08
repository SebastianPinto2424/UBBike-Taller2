import '../helpers/env-setup';
import '../helpers/prisma-mock';
import { prismaMock } from '../helpers/prisma-mock';

jest.mock('../../src/modulos/auditoria/auditoria.servicio', () => ({
  registrarAuditoria: jest.fn().mockResolvedValue(undefined)
}));

jest.mock('../../src/modulos/notificaciones/notificacion.servicio', () => ({
  crearNotificacion: jest.fn().mockResolvedValue(undefined)
}));

jest.mock('../../src/modulos/correos/correo.servicio', () => ({
  crearCorreoCuentaAdministrativa: jest
    .fn()
    .mockReturnValue({ asunto: 'Cuenta UBBike', texto: 'texto', html: 'html' }),
  crearCorreoCuentaDesactivada: jest
    .fn()
    .mockReturnValue({ asunto: 'Cuenta desactivada', texto: 'texto', html: 'html' }),
  crearCorreoCuentaReactivada: jest
    .fn()
    .mockReturnValue({ asunto: 'Cuenta reactivada', texto: 'texto', html: 'html' }),
  crearCorreoRolActualizado: jest
    .fn()
    .mockReturnValue({ asunto: 'Rol actualizado', texto: 'texto', html: 'html' }),
  crearCorreoVerificacion: jest
    .fn()
    .mockReturnValue({ asunto: 'Verificar correo', texto: 'texto', html: 'html' }),
  enviarCorreo: jest.fn().mockResolvedValue(undefined)
}));

import {
  actualizarPermisosUsuario,
  crearUsuarioAdmin,
  eliminarUsuarioAdmin,
  reenviarCorreoAccesoAdmin,
  reenviarVerificacionCorreoAdmin
} from '../../src/modulos/usuarios/usuario.servicio';
import { RolUsuario } from '../../src/modulos/usuarios/rol-usuario';
import {
  crearCorreoCuentaAdministrativa,
  crearCorreoCuentaDesactivada,
  crearCorreoCuentaReactivada,
  crearCorreoRolActualizado,
  crearCorreoVerificacion,
  enviarCorreo
} from '../../src/modulos/correos/correo.servicio';

const usuarioBase = {
  id: 'usuario-1',
  nombre: 'Guardia Prueba',
  correo: 'guardia.externo@correo.cl',
  rut: null,
  rol: RolUsuario.GUARDIA,
  contrasenaHash: '$2a$12$placeholder',
  correoVerificado: true,
  registroParcial: false,
  debeCambiarContrasena: false,
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
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('crea guardias con correo externo y acceso pendiente por correo', async () => {
    prismaMock.usuario.findUnique.mockResolvedValue(null);
    prismaMock.usuario.create.mockResolvedValue(usuarioBase as any);

    const resultado = await crearUsuarioAdmin({
      nombre: usuarioBase.nombre,
      correo: usuarioBase.correo,
      rol: RolUsuario.GUARDIA
    });

    expect(resultado.correo).toBe(usuarioBase.correo);
    expect(prismaMock.usuario.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          correo: usuarioBase.correo,
          rol: RolUsuario.GUARDIA,
          correoVerificado: false,
          cuentaActiva: true,
          debeCambiarContrasena: true,
          tokenCambioContrasena: expect.any(String),
          tokenCambioContrasenaExpiraEn: expect.any(Date)
        })
      })
    );
    expect(crearCorreoCuentaAdministrativa).toHaveBeenCalledWith(
      usuarioBase.nombre,
      expect.stringContaining('/cambiar-contrasena?token='),
      24,
      RolUsuario.GUARDIA
    );
    expect(enviarCorreo).toHaveBeenCalledWith(
      expect.objectContaining({
        para: usuarioBase.correo,
        asunto: 'Cuenta UBBike'
      })
    );
  });

  it('reactiva cuenta eliminada al reutilizar el RUT con correo nuevo', async () => {
    const eliminado = {
      ...usuarioBase,
      id: 'usuario-eliminado',
      correo: 'correo.antiguo@ubiobio.cl',
      rut: '12.345.678-9',
      cuentaActiva: false,
      eliminadoEn: new Date()
    };
    const restaurado = {
      ...eliminado,
      nombre: 'Guardia Reactivado',
      correo: 'correo.nuevo@ubiobio.cl',
      cuentaActiva: true,
      eliminadoEn: null,
      versionSesion: 1
    };
    prismaMock.usuario.findUnique
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(eliminado as any);
    prismaMock.usuario.update.mockResolvedValue(restaurado as any);

    const resultado = await crearUsuarioAdmin({
      nombre: restaurado.nombre,
      correo: restaurado.correo,
      rut: eliminado.rut,
      rol: RolUsuario.GUARDIA
    });

    expect(resultado.id).toBe(eliminado.id);
    expect(prismaMock.usuario.create).not.toHaveBeenCalled();
    expect(prismaMock.usuario.update).toHaveBeenCalledWith({
      where: { id: eliminado.id },
      data: expect.objectContaining({
        correo: restaurado.correo,
        rut: eliminado.rut,
        cuentaActiva: true,
        eliminadoEn: null,
        correoVerificado: false,
        debeCambiarContrasena: true,
        tokenCambioContrasena: expect.any(String),
        tokenCambioContrasenaExpiraEn: expect.any(Date),
        versionSesion: { increment: 1 }
      })
    });
    expect(enviarCorreo).toHaveBeenCalledWith(
      expect.objectContaining({
        para: restaurado.correo,
        asunto: 'Cuenta UBBike'
      })
    );
  });

  it('bloquea si correo y RUT pertenecen a dos cuentas eliminadas distintas', async () => {
    const eliminadoPorCorreo = {
      ...usuarioBase,
      id: 'usuario-correo',
      correo: 'correo.nuevo@ubiobio.cl',
      rut: null,
      eliminadoEn: new Date()
    };
    const eliminadoPorRut = {
      ...usuarioBase,
      id: 'usuario-rut',
      correo: 'correo.antiguo@ubiobio.cl',
      rut: '12.345.678-9',
      eliminadoEn: new Date()
    };
    prismaMock.usuario.findUnique
      .mockResolvedValueOnce(eliminadoPorCorreo as any)
      .mockResolvedValueOnce(eliminadoPorRut as any);

    await expect(
      crearUsuarioAdmin({
        nombre: 'Caso Duplicado',
        correo: eliminadoPorCorreo.correo,
        rut: eliminadoPorRut.rut,
        rol: RolUsuario.GUARDIA
      })
    ).rejects.toMatchObject({ statusCode: 409 });
    expect(prismaMock.usuario.update).not.toHaveBeenCalled();
    expect(prismaMock.usuario.create).not.toHaveBeenCalled();
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
    expect(crearCorreoCuentaDesactivada).toHaveBeenCalledWith(usuarioBase.nombre);
    expect(enviarCorreo).toHaveBeenCalledWith(
      expect.objectContaining({
        para: usuarioBase.correo,
        asunto: 'Cuenta desactivada'
      })
    );
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

describe('reenviarVerificacionCorreoAdmin', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('genera nuevo token y reenvia correo cuando esta pendiente', async () => {
    const pendiente = {
      ...usuarioBase,
      correoVerificado: false,
      tokenVerificacionCorreo: null,
      tokenVerificacionCorreoExpiraEn: null
    };
    prismaMock.usuario.findUnique.mockResolvedValue(pendiente as any);
    prismaMock.usuario.update.mockResolvedValue({
      ...pendiente,
      tokenVerificacionCorreo: 'hash-token',
      tokenVerificacionCorreoExpiraEn: new Date()
    } as any);

    const resultado = await reenviarVerificacionCorreoAdmin(pendiente.id, 'admin-1');

    expect(resultado.message).toContain('reenviado');
    expect(prismaMock.usuario.update).toHaveBeenCalledWith({
      where: { id: pendiente.id },
      data: expect.objectContaining({
        tokenVerificacionCorreo: expect.any(String),
        tokenVerificacionCorreoExpiraEn: expect.any(Date)
      })
    });
    expect(crearCorreoVerificacion).toHaveBeenCalledWith(
      pendiente.nombre,
      expect.stringContaining('/verificar-correo?token=')
    );
    expect(enviarCorreo).toHaveBeenCalledWith(
      expect.objectContaining({
        para: pendiente.correo,
        asunto: 'Verificar correo'
      })
    );
  });

  it('bloquea si el correo ya esta verificado', async () => {
    prismaMock.usuario.findUnique.mockResolvedValue(usuarioBase as any);

    await expect(reenviarVerificacionCorreoAdmin(usuarioBase.id, 'admin-1')).rejects.toMatchObject({
      statusCode: 409
    });
    expect(prismaMock.usuario.update).not.toHaveBeenCalled();
    expect(enviarCorreo).not.toHaveBeenCalled();
  });
});

describe('reenviarCorreoAccesoAdmin', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('genera un nuevo enlace de acceso para cuentas pendientes de contrasena', async () => {
    const pendiente = {
      ...usuarioBase,
      correoVerificado: false,
      debeCambiarContrasena: true,
      tokenCambioContrasena: 'hash-anterior',
      tokenCambioContrasenaExpiraEn: new Date(Date.now() - 1000)
    };
    prismaMock.usuario.findUnique.mockResolvedValue(pendiente as any);
    prismaMock.usuario.update.mockResolvedValue({
      ...pendiente,
      tokenCambioContrasena: 'hash-nuevo',
      tokenCambioContrasenaExpiraEn: new Date()
    } as any);

    const resultado = await reenviarCorreoAccesoAdmin(pendiente.id, 'admin-1');

    expect(resultado.message).toContain('acceso reenviado');
    expect(prismaMock.usuario.update).toHaveBeenCalledWith({
      where: { id: pendiente.id },
      data: expect.objectContaining({
        tokenCambioContrasena: expect.any(String),
        tokenCambioContrasenaExpiraEn: expect.any(Date)
      })
    });
    expect(crearCorreoCuentaAdministrativa).toHaveBeenCalledWith(
      pendiente.nombre,
      expect.stringContaining('/cambiar-contrasena?token='),
      24,
      RolUsuario.GUARDIA
    );
    expect(enviarCorreo).toHaveBeenCalledWith(
      expect.objectContaining({
        para: pendiente.correo,
        asunto: 'Cuenta UBBike'
      })
    );
  });

  it('bloquea si la cuenta ya tiene contrasena configurada', async () => {
    prismaMock.usuario.findUnique.mockResolvedValue({
      ...usuarioBase,
      debeCambiarContrasena: false
    } as any);

    await expect(reenviarCorreoAccesoAdmin(usuarioBase.id, 'admin-1')).rejects.toMatchObject({
      statusCode: 409
    });
    expect(prismaMock.usuario.update).not.toHaveBeenCalled();
    expect(enviarCorreo).not.toHaveBeenCalled();
  });
});

describe('actualizarPermisosUsuario', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('revoca la verificacion y envia correo si cambia el correo de una cuenta configurada', async () => {
    const correoNuevo = 'nuevo.guardia@correo.cl';
    prismaMock.usuario.findUnique
      .mockResolvedValueOnce(usuarioBase as any)
      .mockResolvedValueOnce(null);
    prismaMock.usuario.update.mockResolvedValue({
      ...usuarioBase,
      correo: correoNuevo,
      correoVerificado: false,
      versionSesion: 1
    } as any);

    await actualizarPermisosUsuario(
      usuarioBase.id,
      { correo: correoNuevo.toUpperCase() },
      'admin-1'
    );

    expect(prismaMock.usuario.update).toHaveBeenCalledWith({
      where: { id: usuarioBase.id },
      data: expect.objectContaining({
        correo: correoNuevo,
        correoVerificado: false,
        tokenVerificacionCorreo: expect.any(String),
        tokenVerificacionCorreoExpiraEn: expect.any(Date),
        versionSesion: { increment: 1 }
      })
    });
    expect(crearCorreoVerificacion).toHaveBeenCalledWith(
      usuarioBase.nombre,
      expect.stringContaining('/verificar-correo?token=')
    );
    expect(enviarCorreo).toHaveBeenCalledWith(
      expect.objectContaining({
        para: correoNuevo,
        asunto: 'Verificar correo'
      })
    );
  });

  it('regenera el correo de acceso si cambia el correo de una cuenta pendiente', async () => {
    const pendiente = {
      ...usuarioBase,
      correoVerificado: false,
      debeCambiarContrasena: true,
      tokenCambioContrasena: 'hash-anterior',
      tokenCambioContrasenaExpiraEn: new Date()
    };
    const correoNuevo = 'guardia.pendiente@correo.cl';
    prismaMock.usuario.findUnique
      .mockResolvedValueOnce(pendiente as any)
      .mockResolvedValueOnce(null);
    prismaMock.usuario.update.mockResolvedValue({
      ...pendiente,
      correo: correoNuevo,
      tokenCambioContrasena: 'hash-nuevo'
    } as any);

    await actualizarPermisosUsuario(pendiente.id, { correo: correoNuevo }, 'admin-1');

    expect(prismaMock.usuario.update).toHaveBeenCalledWith({
      where: { id: pendiente.id },
      data: expect.objectContaining({
        correo: correoNuevo,
        correoVerificado: false,
        tokenVerificacionCorreo: null,
        tokenVerificacionCorreoExpiraEn: null,
        tokenCambioContrasena: expect.any(String),
        tokenCambioContrasenaExpiraEn: expect.any(Date),
        versionSesion: { increment: 1 }
      })
    });
    expect(crearCorreoCuentaAdministrativa).toHaveBeenCalledWith(
      pendiente.nombre,
      expect.stringContaining('/cambiar-contrasena?token='),
      24,
      RolUsuario.GUARDIA
    );
    expect(crearCorreoVerificacion).not.toHaveBeenCalled();
    expect(enviarCorreo).toHaveBeenCalledWith(
      expect.objectContaining({
        para: correoNuevo,
        asunto: 'Cuenta UBBike'
      })
    );
  });

  it('envia correo cuando administracion desactiva una cuenta', async () => {
    prismaMock.usuario.findUnique.mockResolvedValue(usuarioBase as any);
    prismaMock.usuario.update.mockResolvedValue({
      ...usuarioBase,
      cuentaActiva: false,
      versionSesion: 1
    } as any);

    await actualizarPermisosUsuario(usuarioBase.id, { cuentaActiva: false }, 'admin-1');

    expect(crearCorreoCuentaDesactivada).toHaveBeenCalledWith(usuarioBase.nombre);
    expect(enviarCorreo).toHaveBeenCalledWith(
      expect.objectContaining({
        para: usuarioBase.correo,
        asunto: 'Cuenta desactivada'
      })
    );
  });

  it('envia correo cuando administracion reactiva una cuenta', async () => {
    const inactivo = {
      ...usuarioBase,
      cuentaActiva: false
    };
    prismaMock.usuario.findUnique.mockResolvedValue(inactivo as any);
    prismaMock.usuario.update.mockResolvedValue({
      ...inactivo,
      cuentaActiva: true,
      versionSesion: 1
    } as any);

    await actualizarPermisosUsuario(inactivo.id, { cuentaActiva: true }, 'admin-1');

    expect(crearCorreoCuentaReactivada).toHaveBeenCalledWith(inactivo.nombre);
    expect(enviarCorreo).toHaveBeenCalledWith(
      expect.objectContaining({
        para: inactivo.correo,
        asunto: 'Cuenta reactivada'
      })
    );
  });

  it('envia correo cuando administracion cambia el rol', async () => {
    prismaMock.usuario.findUnique.mockResolvedValue(usuarioBase as any);
    prismaMock.usuario.update.mockResolvedValue({
      ...usuarioBase,
      rol: RolUsuario.ADMIN_CENTRAL,
      versionSesion: 1
    } as any);

    await actualizarPermisosUsuario(usuarioBase.id, { rol: RolUsuario.ADMIN_CENTRAL }, 'admin-1');

    expect(crearCorreoRolActualizado).toHaveBeenCalledWith(
      usuarioBase.nombre,
      RolUsuario.GUARDIA,
      RolUsuario.ADMIN_CENTRAL
    );
    expect(enviarCorreo).toHaveBeenCalledWith(
      expect.objectContaining({
        para: usuarioBase.correo,
        asunto: 'Rol actualizado'
      })
    );
  });

  it('bloquea cambiar el correo del ultimo administrador verificado', async () => {
    const administrador = {
      ...usuarioBase,
      rol: RolUsuario.ADMINISTRADOR,
      correoVerificado: true
    };
    prismaMock.usuario.findUnique.mockResolvedValue(administrador as any);
    prismaMock.usuario.count.mockResolvedValue(0);

    await expect(
      actualizarPermisosUsuario(administrador.id, { correo: 'admin.nuevo@ubiobio.cl' }, 'admin-1')
    ).rejects.toMatchObject({
      statusCode: 400
    });

    expect(prismaMock.usuario.update).not.toHaveBeenCalled();
    expect(enviarCorreo).not.toHaveBeenCalled();
  });
});
