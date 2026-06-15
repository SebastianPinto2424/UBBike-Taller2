import { construirStatsBicicletero, contarOcupadosPorBicicletero } from './bicicletero.ocupacion';
import * as bicicleteroRepositorio from './bicicletero.repositorio';

export const listarBicicleteros = async () => {
  const [bicicleteros, ocupadosPorId] = await Promise.all([
    bicicleteroRepositorio.listarActivos(),
    contarOcupadosPorBicicletero()
  ]);

  return bicicleteros.map((bicicletero) =>
    construirStatsBicicletero(bicicletero, ocupadosPorId[bicicletero.id] ?? 0)
  );
};
