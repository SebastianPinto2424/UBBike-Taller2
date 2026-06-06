import { SolicitudAutenticada } from '../../../comun/middlewares/autenticacion.middleware';
import { controladorAsync } from '../../../comun/utils/controlador-async';
import {
  obtenerAsignacionActivaGuardia,
  seleccionarBicicleteroGuardia
} from './asignacion-guardia.servicio';

export const obtenerMiBicicletero = controladorAsync<SolicitudAutenticada>(async (req, res) => {
  const asignacion = await obtenerAsignacionActivaGuardia(req.usuario!.usuarioId);
  return res.status(200).json({
    asignacion,
    bicicletero: asignacion?.bicicletero ?? null
  });
});

export const seleccionarMiBicicletero = controladorAsync<SolicitudAutenticada>(async (req, res) => {
  const asignacion = await seleccionarBicicleteroGuardia(
    req.usuario!.usuarioId,
    req.body.bicicleteroId
  );

  return res.status(200).json({
    asignacion,
    bicicletero: asignacion.bicicletero
  });
});
