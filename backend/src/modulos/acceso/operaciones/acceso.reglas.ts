import { ErrorHttp } from '../../../comun/errors/error-http';
import { TipoMovimiento } from '../../historial/tipo-movimiento';

type BicicletaConEstado = {
  dentroBicicletero: boolean;
};

export const validarReglaMovimiento = (bicicleta: BicicletaConEstado, tipo: TipoMovimiento) => {
  if (tipo === TipoMovimiento.INGRESO && bicicleta.dentroBicicletero) {
    throw new ErrorHttp(409, 'La bicicleta ya registra ingreso activo');
  }

  if (tipo === TipoMovimiento.RETIRO && !bicicleta.dentroBicicletero) {
    throw new ErrorHttp(409, 'La bicicleta no registra ingreso activo');
  }
};
