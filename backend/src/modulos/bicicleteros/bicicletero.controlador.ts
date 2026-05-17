import { controladorAsync } from '../../comun/utils/controlador-async';
import { listarBicicleteros } from './bicicletero.servicio';

export const listar = controladorAsync(async (_req, res) => {
  const bicicleteros = await listarBicicleteros();
  return res.status(200).json({ bicicleteros });
});
