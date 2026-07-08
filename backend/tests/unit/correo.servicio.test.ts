import '../helpers/env-setup';

import { crearCorreoMovimiento } from '../../src/modulos/correos/correo.servicio';

describe('crearCorreoMovimiento', () => {
  it('mantiene la misma estructura aunque falten datos opcionales de la bicicleta', () => {
    const correo = crearCorreoMovimiento({
      nombre: 'Estudiante UBB',
      tipo: 'RETIRO',
      estado: 'CONFIRMADO',
      origen: 'QR',
      bicicleta: 'Bici de prueba',
      marca: null,
      modelo: '',
      color: null,
      aro: undefined,
      numeroSerie: null,
      bicicletero: 'Bicicletero FACE',
      guardia: 'Guardia Demo',
      fecha: new Date('2026-07-07T12:00:00.000Z'),
      fotoCid: 'foto-bicicleta-movimiento@ubbike'
    });

    expect(correo.texto).toContain('Marca: No informado');
    expect(correo.texto).toContain('Modelo: No informado');
    expect(correo.texto).toContain('Color: No informado');
    expect(correo.texto).toContain('Aro: No informado');
    expect(correo.texto).toContain('serie: No informado');
    expect(correo.html).toContain('cid:foto-bicicleta-movimiento@ubbike');
  });
});
