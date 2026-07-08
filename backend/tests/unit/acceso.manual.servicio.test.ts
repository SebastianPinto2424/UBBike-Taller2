import '../helpers/env-setup';
import '../helpers/prisma-mock';
import { prismaMock } from '../helpers/prisma-mock';

jest.mock('../../src/modulos/correos/correo.servicio', () => ({
  crearCorreoCompletarRegistro: jest.fn(),
  crearCorreoMovimiento: jest.fn(),
  crearCorreoMovimientoManual: jest.fn(),
  enviarCorreo: jest.fn().mockResolvedValue(undefined)
}));

jest.mock('../../src/modulos/auditoria/auditoria.servicio', () => ({
  registrarAuditoria: jest.fn().mockResolvedValue(undefined)
}));

jest.mock('../../src/modulos/notificaciones/notificacion.servicio', () => ({
  crearNotificacion: jest.fn().mockResolvedValue(undefined),
  notificarUsuariosPorRol: jest.fn().mockResolvedValue(undefined)
}));

import { registrarGestionManual } from '../../src/modulos/acceso/operaciones/acceso.servicio';
import { TipoMovimiento } from '../../src/modulos/historial/tipo-movimiento';
import { RolUsuario } from '../../src/modulos/usuarios/rol-usuario';

describe('registrarGestionManual', () => {
  it('bloquea el retiro manual si el usuario tiene registro parcial (debe completar registro)', async () => {
    prismaMock.usuario.findFirst.mockResolvedValue({
      id: 'user-uuid-1',
      correo: 'estudiante@alumnos.ubiobio.cl',
      rut: '11.111.111-1',
      registroParcial: true
    } as never);

    await expect(
      registrarGestionManual({
        guardiaId: 'guardia-uuid-1',
        rol: RolUsuario.GUARDIA,
        correo: 'estudiante@alumnos.ubiobio.cl',
        rut: '11.111.111-1',
        tipo: TipoMovimiento.RETIRO
      })
    ).rejects.toMatchObject({ statusCode: 409 });

    expect(prismaMock.movimiento.create).not.toHaveBeenCalled();
  });
});
