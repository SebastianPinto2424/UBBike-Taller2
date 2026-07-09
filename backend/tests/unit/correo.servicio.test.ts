import '../helpers/env-setup';

import {
  crearCorreoCuentaAdministrativa,
  crearCorreoMovimiento
} from '../../src/modulos/correos/correo.servicio';

describe('crearCorreoCuentaAdministrativa', () => {
  it('incluye siempre el boton y el enlace para crear la contrasena', () => {
    const enlace =
      'https://ubbike.example/cambiar-contrasena?token=token-seguro&modo=activacion';
    const correo = crearCorreoCuentaAdministrativa(
      'Guardia Prueba',
      enlace,
      24,
      'GUARDIA'
    );

    expect(correo.asunto).toBe('Te damos la bienvenida a UBBike — activa tu cuenta de guardia');
    expect(correo.texto).toContain(enlace);
    expect(correo.html).toContain(
      'href="https://ubbike.example/cambiar-contrasena?token=token-seguro&amp;modo=activacion"'
    );
    expect(correo.html).toContain('Crear mi contraseña');
    expect(correo.html).toContain('vence en 24 horas');
  });
});

describe('crearCorreoMovimiento', () => {
  it('mantiene todos los campos y no agrega fecha ni hora al asunto', () => {
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

    expect(correo.asunto).toBe('Retiro confirmado: Bici de prueba en UBBike');
    expect(correo.asunto).not.toMatch(/\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{1,2}:\d{2}/);
    expect(correo.html).toContain('<strong>Operación:</strong> Retiro');
    expect(correo.html).toContain('<strong>Resultado:</strong> confirmado');
    expect(correo.html).toContain('<strong>Origen:</strong> por código QR');
    expect(correo.html).toContain('<strong>Bicicletero:</strong> Bicicletero FACE');
    expect(correo.html).toContain('<strong>Guardia:</strong> Guardia Demo');
    expect(correo.html).toContain('<strong>Descripción:</strong> Bici de prueba');
    expect(correo.texto).toContain('Marca: No informado');
    expect(correo.texto).toContain('Modelo: No informado');
    expect(correo.texto).toContain('Color: No informado');
    expect(correo.texto).toContain('Aro: No informado');
    expect(correo.texto).toContain('serie: No informado');
    expect(correo.html).toContain('cid:foto-bicicleta-movimiento@ubbike');
  });
});
