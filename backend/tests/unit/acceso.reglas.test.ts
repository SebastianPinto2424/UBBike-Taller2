import '../helpers/env-setup';
import { validarReglaMovimiento } from '../../src/modulos/acceso/operaciones/acceso.reglas';
import { TipoMovimiento } from '../../src/modulos/historial/tipo-movimiento';

describe('validarReglaMovimiento', () => {
  it('lanza 409 si intenta INGRESO y bicicleta ya esta dentro', () => {
    expect(() =>
      validarReglaMovimiento({ dentroBicicletero: true }, TipoMovimiento.INGRESO)
    ).toThrow('La bicicleta ya registra ingreso activo');
  });

  it('lanza 409 si intenta RETIRO y bicicleta no esta dentro', () => {
    expect(() =>
      validarReglaMovimiento({ dentroBicicletero: false }, TipoMovimiento.RETIRO)
    ).toThrow('La bicicleta no registra ingreso activo');
  });

  it('no lanza si INGRESO y bicicleta esta fuera', () => {
    expect(() =>
      validarReglaMovimiento({ dentroBicicletero: false }, TipoMovimiento.INGRESO)
    ).not.toThrow();
  });

  it('no lanza si RETIRO y bicicleta esta dentro', () => {
    expect(() =>
      validarReglaMovimiento({ dentroBicicletero: true }, TipoMovimiento.RETIRO)
    ).not.toThrow();
  });
});
