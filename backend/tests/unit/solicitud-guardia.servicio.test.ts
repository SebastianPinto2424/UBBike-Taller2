import '../helpers/env-setup';
import '../helpers/prisma-mock';
import { prismaMock } from '../helpers/prisma-mock';

jest.mock('../../src/modulos/notificaciones/notificacion.servicio', () => ({
  crearNotificacion: jest.fn().mockResolvedValue(undefined),
  notificarUsuariosPorRol: jest.fn().mockResolvedValue(undefined)
}));

jest.mock('../../src/modulos/auditoria/auditoria.servicio', () => ({
  registrarAuditoria: jest.fn().mockResolvedValue(undefined)
}));

import { actualizarEstadoSolicitudGuardia } from '../../src/modulos/acceso/solicitudes/solicitud-guardia.servicio';
import { EstadoSolicitudGuardia } from '../../src/modulos/acceso/solicitudes/estado-solicitud-guardia';
import { RolUsuario } from '../../src/modulos/usuarios/rol-usuario';

const solicitudCerradaBase = {
  id: 'sol-uuid-1',
  estado: EstadoSolicitudGuardia.RESUELTA,
  guardiaAsignado: null,
  solicitadaPorUsuario: {
    id: 'user-uuid-1',
    nombre: 'Estudiante',
    correo: 'estudiante@alumnos.ubiobio.cl',
    rut: null,
    rol: RolUsuario.ESTUDIANTE
  },
  bicicletero: { id: 'bic-uuid-1', nombre: 'Bicicletero FACE', ubicacion: 'FACE' }
};

describe('actualizarEstadoSolicitudGuardia', () => {
  it('no permite reabrir una solicitud ya cerrada (RESUELTA -> EN_CAMINO)', async () => {
    prismaMock.solicitudGuardia.findUnique.mockResolvedValue(solicitudCerradaBase as never);

    await expect(
      actualizarEstadoSolicitudGuardia(
        'admin-uuid-1',
        RolUsuario.ADMIN_CENTRAL,
        'sol-uuid-1',
        EstadoSolicitudGuardia.EN_CAMINO
      )
    ).rejects.toMatchObject({ statusCode: 409 });

    expect(prismaMock.solicitudGuardia.update).not.toHaveBeenCalled();
  });

  it('tampoco permite reabrir una solicitud CANCELADA', async () => {
    prismaMock.solicitudGuardia.findUnique.mockResolvedValue({
      ...solicitudCerradaBase,
      estado: EstadoSolicitudGuardia.CANCELADA
    } as never);

    await expect(
      actualizarEstadoSolicitudGuardia(
        'admin-uuid-1',
        RolUsuario.ADMIN_CENTRAL,
        'sol-uuid-1',
        EstadoSolicitudGuardia.EN_CAMINO
      )
    ).rejects.toMatchObject({ statusCode: 409 });
  });
});
