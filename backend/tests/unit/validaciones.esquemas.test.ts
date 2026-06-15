import {
  esquemaCambioContrasena,
  esquemaCompletarRegistro,
  esquemaLogin,
  esquemaRefreshToken,
  esquemaRegistro,
  esquemaSolicitudCambioContrasena,
  esquemaVerificarCorreo
} from '../../src/modulos/autenticacion/autenticacion.validacion';
import {
  esquemaActualizarBicicleta,
  esquemaCrearBicicleta
} from '../../src/modulos/bicicletas/bicicleta.validacion';
import {
  esquemaActualizarPermisosUsuario,
  esquemaCrearUsuario
} from '../../src/modulos/usuarios/usuario.validacion';
import {
  esquemaActualizarEstadoIncidencia,
  esquemaCrearIncidencia
} from '../../src/modulos/incidencias/incidencia.validacion';
import {
  esquemaConfirmarQr,
  esquemaDenegarQr,
  esquemaGestionManual
} from '../../src/modulos/acceso/operaciones/acceso.validacion';
import {
  esquemaActualizarEstadoSolicitudGuardia,
  esquemaCrearSolicitudGuardia,
  esquemaNotificarGuardiaSolicitud
} from '../../src/modulos/acceso/solicitudes/solicitud-guardia.validacion';
import { esquemaGenerarQr, esquemaValidarQr } from '../../src/modulos/qr/qr.validacion';
import { esquemaSeleccionarBicicleteroGuardia } from '../../src/modulos/acceso/asignaciones/asignacion-guardia.validacion';
import { TipoIncidencia } from '../../src/modulos/incidencias/tipo-incidencia';
import { EstadoIncidencia } from '../../src/modulos/incidencias/estado-incidencia';
import { TipoMovimiento } from '../../src/modulos/historial/tipo-movimiento';
import { RolUsuario } from '../../src/modulos/usuarios/rol-usuario';
import { TipoSolicitudGuardia } from '../../src/modulos/acceso/solicitudes/tipo-solicitud-guardia';
import { EstadoSolicitudGuardia } from '../../src/modulos/acceso/solicitudes/estado-solicitud-guardia';

const UUID = '11111111-1111-4111-8111-111111111111';
const CONTRASENA_OK = 'Abcdefg1!xyz';
const NOMBRE_OK = 'Juan Carlos Pérez Soto';

const esValido = (esquema: { validate: (v: unknown) => { error?: unknown } }, valor: unknown) =>
  esquema.validate(valor).error === undefined;

describe('esquemaRegistro', () => {
  const base = {
    nombre: NOMBRE_OK,
    correo: 'juan@alumnos.ubiobio.cl',
    contrasena: CONTRASENA_OK
  };

  it('acepta un registro completo y válido', () => {
    expect(esValido(esquemaRegistro, base)).toBe(true);
  });

  it('acepta RUT chileno válido (dígito verificador numérico, 0 y K)', () => {
    expect(esValido(esquemaRegistro, { ...base, rut: '12.345.678-5' })).toBe(true);
    expect(esValido(esquemaRegistro, { ...base, rut: '12.345.675-0' })).toBe(true);
    expect(esValido(esquemaRegistro, { ...base, rut: '12.345.670-K' })).toBe(true);
  });

  it('rechaza RUT con dígito verificador incorrecto', () => {
    expect(esValido(esquemaRegistro, { ...base, rut: '12.345.678-9' })).toBe(false);
  });

  it('exige guion en el RUT (rechaza punto en vez de guion)', () => {
    expect(esValido(esquemaRegistro, { ...base, rut: '12.345.678.5' })).toBe(false);
    expect(esValido(esquemaRegistro, { ...base, rut: '123456785' })).toBe(false);
  });

  it('acepta RUT con guion sin puntos y los agrega automáticamente', () => {
    const { error, value } = esquemaRegistro.validate({ ...base, rut: '12345678-5' });
    expect(error).toBeUndefined();
    expect(value.rut).toBe('12.345.678-5');
  });

  it('nombre: exige dos nombres y dos apellidos (4 palabras)', () => {
    expect(esValido(esquemaRegistro, { ...base, nombre: 'Juan Carlos Pérez Soto' })).toBe(true);
    expect(esValido(esquemaRegistro, { ...base, nombre: 'Juan Pérez' })).toBe(false);
    expect(esValido(esquemaRegistro, { ...base, nombre: 'Juan Carlos Pérez' })).toBe(false);
    expect(esValido(esquemaRegistro, { ...base, nombre: 'Juan Carlos Pérez Soto Rojas' })).toBe(
      false
    );
    expect(esValido(esquemaRegistro, { ...base, nombre: 'Juan 123 Pérez Soto' })).toBe(false);
  });

  it('rechaza correo con formato inválido', () => {
    expect(esValido(esquemaRegistro, { ...base, correo: 'no-es-correo' })).toBe(false);
  });

  it('rechaza correo no institucional', () => {
    expect(esValido(esquemaRegistro, { ...base, correo: 'juan@gmail.com' })).toBe(false);
  });

  it('exige campos obligatorios', () => {
    expect(esValido(esquemaRegistro, { correo: base.correo, contrasena: base.contrasena })).toBe(
      false
    );
    expect(esValido(esquemaRegistro, { nombre: base.nombre, contrasena: base.contrasena })).toBe(
      false
    );
    expect(esValido(esquemaRegistro, { nombre: base.nombre, correo: base.correo })).toBe(false);
  });
});

describe('esquemaRegistro · política de contraseña', () => {
  const con = (contrasena: string) =>
    esValido(esquemaRegistro, {
      nombre: NOMBRE_OK,
      correo: 'juan@alumnos.ubiobio.cl',
      contrasena
    });

  it('acepta exactamente 12 caracteres con las 4 clases', () => {
    expect(con('Abcdefg1!xyz')).toBe(true);
  });

  it('rechaza con 11 caracteres (bajo el mínimo)', () => {
    expect(con('Abcdef1!xyz')).toBe(false);
  });

  it('acepta el límite máximo de 72 y rechaza 73', () => {
    expect(con('Aa1!' + 'a'.repeat(68))).toBe(true);
    expect(con('Aa1!' + 'a'.repeat(69))).toBe(false);
  });

  it('rechaza si falta mayúscula / minúscula / dígito / símbolo', () => {
    expect(con('abcdefg1!xyz')).toBe(false);
    expect(con('ABCDEFG1!XYZ')).toBe(false);
    expect(con('Abcdefgh!xyz')).toBe(false);
    expect(con('Abcdefg12xyz')).toBe(false);
  });
});

describe('esquemaLogin', () => {
  it('acepta correo válido + contraseña (sin exigir complejidad)', () => {
    expect(esValido(esquemaLogin, { correo: 'a@x.cl', contrasena: 'lo-que-sea' })).toBe(true);
  });

  it('rechaza correo inválido o campos faltantes', () => {
    expect(esValido(esquemaLogin, { correo: 'roto', contrasena: 'x' })).toBe(false);
    expect(esValido(esquemaLogin, { correo: 'a@x.cl' })).toBe(false);
  });
});

describe('esquemaSolicitudCambioContrasena y esquemaVerificarCorreo', () => {
  it('solicitud de cambio exige correo valido', () => {
    expect(esValido(esquemaSolicitudCambioContrasena, { correo: 'persona@ubiobio.cl' })).toBe(true);
    expect(
      esValido(esquemaSolicitudCambioContrasena, { correo: 'persona@alumnos.ubiobio.cl' })
    ).toBe(true);
    expect(esValido(esquemaSolicitudCambioContrasena, { correo: 'correo-roto' })).toBe(false);
    expect(esValido(esquemaSolicitudCambioContrasena, { correo: 'persona@gmail.com' })).toBe(false);
    expect(esValido(esquemaSolicitudCambioContrasena, {})).toBe(false);
  });

  it('verificacion de correo exige token no vacio', () => {
    expect(esValido(esquemaVerificarCorreo, { token: 'token-valido' })).toBe(true);
    expect(esValido(esquemaVerificarCorreo, { token: '   ' })).toBe(false);
    expect(esValido(esquemaVerificarCorreo, {})).toBe(false);
  });
});

describe('esquemaRefreshToken', () => {
  it('exige usuarioId con formato UUID', () => {
    expect(esValido(esquemaRefreshToken, { usuarioId: UUID, refreshToken: 't' })).toBe(true);
    expect(esValido(esquemaRefreshToken, { usuarioId: 'no-uuid', refreshToken: 't' })).toBe(false);
  });
});

describe('esquemaCompletarRegistro y esquemaCambioContrasena', () => {
  it('exigen token + contraseña fuerte', () => {
    expect(
      esValido(esquemaCompletarRegistro, {
        token: 't',
        nombre: NOMBRE_OK,
        contrasena: CONTRASENA_OK
      })
    ).toBe(true);
    expect(
      esValido(esquemaCompletarRegistro, { token: 't', nombre: NOMBRE_OK, contrasena: 'debil' })
    ).toBe(false);
    expect(
      esValido(esquemaCompletarRegistro, { token: 't', nombre: 'Ana', contrasena: CONTRASENA_OK })
    ).toBe(false);
    expect(esValido(esquemaCambioContrasena, { token: 't', contrasena: CONTRASENA_OK })).toBe(true);
    expect(esValido(esquemaCambioContrasena, { token: '', contrasena: CONTRASENA_OK })).toBe(false);
  });
});

describe('esquemaCrearBicicleta', () => {
  it('acepta lo mínimo y aplica activar=false por defecto', () => {
    const { error, value } = esquemaCrearBicicleta.validate({ descripcion: 'Bici roja' });
    expect(error).toBeUndefined();
    expect(value.activar).toBe(false);
  });

  it('descripcion: límite inferior (3 ok, 2 falla)', () => {
    expect(esValido(esquemaCrearBicicleta, { descripcion: 'abc' })).toBe(true);
    expect(esValido(esquemaCrearBicicleta, { descripcion: 'ab' })).toBe(false);
  });

  it('descripcion: exige texto real y limita a 100 caracteres', () => {
    expect(esValido(esquemaCrearBicicleta, { descripcion: '---' })).toBe(false);
    expect(esValido(esquemaCrearBicicleta, { descripcion: 'B'.repeat(100) })).toBe(true);
    expect(esValido(esquemaCrearBicicleta, { descripcion: 'B'.repeat(101) })).toBe(false);
  });

  it('valida marca, modelo, color, aro y numero de serie', () => {
    expect(
      esValido(esquemaCrearBicicleta, {
        descripcion: 'Bici azul',
        marca: 'Oxford',
        modelo: 'ATX 720',
        color: 'Azul',
        aro: '29',
        numeroSerie: 'AB-1234'
      })
    ).toBe(true);
    expect(esValido(esquemaCrearBicicleta, { descripcion: 'Bici', marca: 'A' })).toBe(false);
    expect(esValido(esquemaCrearBicicleta, { descripcion: 'Bici', marca: 'Marca@' })).toBe(false);
    expect(esValido(esquemaCrearBicicleta, { descripcion: 'Bici', color: 'Azul123' })).toBe(false);
    expect(esValido(esquemaCrearBicicleta, { descripcion: 'Bici', aro: 'R26' })).toBe(false);
    expect(esValido(esquemaCrearBicicleta, { descripcion: 'Bici', numeroSerie: 'A 12' })).toBe(
      false
    );
  });

  it('normaliza color y aro desde alias conocidos', () => {
    const { error, value } = esquemaCrearBicicleta.validate({
      descripcion: 'Bici urbana',
      color: 'plomo y azul marino',
      aro: '700C'
    });

    expect(error).toBeUndefined();
    expect(value.color).toBe('Gris / Azul marino');
    expect(value.aro).toBe('29');
  });

  it('acepta combinaciones de hasta 3 colores validos', () => {
    const { error, value } = esquemaCrearBicicleta.validate({
      descripcion: 'Bici de ruta',
      color: 'negro / rojo / plateado'
    });

    expect(error).toBeUndefined();
    expect(value.color).toBe('Negro / Rojo / Plateado');
    expect(
      esValido(esquemaCrearBicicleta, { descripcion: 'Bici', color: 'negro/rojo/azul/verde' })
    ).toBe(false);
    expect(
      esValido(esquemaCrearBicicleta, { descripcion: 'Bici', color: 'negro/rojo/inventado' })
    ).toBe(false);
  });

  it('normaliza numero de serie a mayusculas', () => {
    const { error, value } = esquemaCrearBicicleta.validate({
      descripcion: 'Bici roja',
      numeroSerie: 'ab-1234'
    });

    expect(error).toBeUndefined();
    expect(value.numeroSerie).toBe('AB-1234');
  });

  it('acepta foto base64 con formato data-uri válido y rechaza basura', () => {
    expect(
      esValido(esquemaCrearBicicleta, {
        descripcion: 'Bici',
        fotoUrl: 'data:image/png;base64,iVBORw0KGgo='
      })
    ).toBe(true);
    expect(
      esValido(esquemaCrearBicicleta, { descripcion: 'Bici', fotoUrl: 'javascript:alert(1)' })
    ).toBe(false);
  });
});

describe('esquemaActualizarBicicleta', () => {
  it('rechaza un body vacío (.min(1))', () => {
    expect(esValido(esquemaActualizarBicicleta, {})).toBe(false);
  });

  it('acepta una actualización parcial', () => {
    expect(esValido(esquemaActualizarBicicleta, { color: 'Azul' })).toBe(true);
  });
});

describe('esquemaActualizarPermisosUsuario', () => {
  it('rechaza body vacío y rol inválido', () => {
    expect(esValido(esquemaActualizarPermisosUsuario, {})).toBe(false);
    expect(esValido(esquemaActualizarPermisosUsuario, { rol: 'SUPERADMIN' })).toBe(false);
  });

  it('acepta rol válido del enum', () => {
    expect(esValido(esquemaActualizarPermisosUsuario, { rol: RolUsuario.GUARDIA })).toBe(true);
  });
});

describe('esquemaCrearUsuario admin', () => {
  const base = {
    nombre: NOMBRE_OK,
    correo: 'guardia.extern@correo.cl',
    rol: RolUsuario.GUARDIA,
    contrasena: CONTRASENA_OK
  };

  it('acepta crear guardia con correo no institucional', () => {
    expect(esValido(esquemaCrearUsuario, base)).toBe(true);
  });

  it('rechaza rol invalido y contrasena debil', () => {
    expect(esValido(esquemaCrearUsuario, { ...base, rol: 'SUPERADMIN' })).toBe(false);
    expect(esValido(esquemaCrearUsuario, { ...base, contrasena: 'debil' })).toBe(false);
  });
});

describe('esquemaCrearIncidencia', () => {
  it('aplica tipo=OTRO por defecto', () => {
    const { error, value } = esquemaCrearIncidencia.validate({
      bicicleteroId: UUID,
      descripcion: 'Algo no funciona'
    });
    expect(error).toBeUndefined();
    expect(value.tipo).toBe(TipoIncidencia.OTRO);
  });

  it('exige bicicleteroId UUID y descripcion >= 8', () => {
    expect(
      esValido(esquemaCrearIncidencia, { bicicleteroId: 'x', descripcion: 'larga okay' })
    ).toBe(false);
    expect(esValido(esquemaCrearIncidencia, { bicicleteroId: UUID, descripcion: 'corta' })).toBe(
      false
    );
  });
});

describe('esquemaActualizarEstadoIncidencia · respuesta condicional', () => {
  it('exige respuesta (>=8) al RESOLVER o DESCARTAR', () => {
    expect(esValido(esquemaActualizarEstadoIncidencia, { estado: EstadoIncidencia.RESUELTA })).toBe(
      false
    );
    expect(
      esValido(esquemaActualizarEstadoIncidencia, {
        estado: EstadoIncidencia.RESUELTA,
        respuesta: 'corto'
      })
    ).toBe(false);
    expect(
      esValido(esquemaActualizarEstadoIncidencia, {
        estado: EstadoIncidencia.RESUELTA,
        respuesta: 'Se reparó el lector QR.'
      })
    ).toBe(true);
  });

  it('NO exige respuesta para estados no terminales', () => {
    expect(
      esValido(esquemaActualizarEstadoIncidencia, { estado: EstadoIncidencia.EN_REVISION })
    ).toBe(true);
  });
});

describe('esquemaDenegarQr', () => {
  it('exige motivo (>=3) y token', () => {
    expect(esValido(esquemaDenegarQr, { token: 't', motivo: 'sin permiso' })).toBe(true);
    expect(esValido(esquemaDenegarQr, { token: 't', motivo: 'ab' })).toBe(false);
    expect(esValido(esquemaDenegarQr, { token: 't' })).toBe(false);
  });
});

describe('esquemaConfirmarQr', () => {
  it('exige token; bicicleteroId/comentario son opcionales', () => {
    expect(esValido(esquemaConfirmarQr, { token: 't' })).toBe(true);
    expect(esValido(esquemaConfirmarQr, {})).toBe(false);
  });
});

describe('esquemaGenerarQr y esquemaValidarQr', () => {
  it('generar QR acepta body vacio y campos opcionales validos', () => {
    expect(esValido(esquemaGenerarQr, {})).toBe(true);
    expect(
      esValido(esquemaGenerarQr, {
        bicicletaId: UUID,
        bicicleteroId: UUID,
        tipo: TipoMovimiento.RETIRO
      })
    ).toBe(true);
  });

  it('generar QR rechaza uuid o tipo invalido', () => {
    expect(esValido(esquemaGenerarQr, { bicicletaId: 'no-uuid' })).toBe(false);
    expect(esValido(esquemaGenerarQr, { tipo: 'PAUSA' })).toBe(false);
  });

  it('validar QR exige token no vacio', () => {
    expect(esValido(esquemaValidarQr, { token: 'abc' })).toBe(true);
    expect(esValido(esquemaValidarQr, { token: '   ' })).toBe(false);
    expect(esValido(esquemaValidarQr, {})).toBe(false);
  });
});

describe('esquemaGestionManual', () => {
  const base = { correo: 'a@alumnos.ubiobio.cl', tipo: TipoMovimiento.INGRESO };

  it('exige al menos correo o rut (.or)', () => {
    expect(esValido(esquemaGestionManual, { tipo: TipoMovimiento.INGRESO })).toBe(false);
    expect(esValido(esquemaGestionManual, base)).toBe(true);
  });

  it('exige tipo de movimiento', () => {
    expect(esValido(esquemaGestionManual, { correo: 'a@x.cl' })).toBe(false);
  });

  it('si denegar=true exige motivo (>=3)', () => {
    expect(esValido(esquemaGestionManual, { ...base, denegar: true })).toBe(false);
    expect(esValido(esquemaGestionManual, { ...base, denegar: true, motivo: 'ab' })).toBe(false);
    expect(esValido(esquemaGestionManual, { ...base, denegar: true, motivo: 'sin cupo' })).toBe(
      true
    );
  });
});

describe('esquemaCrearSolicitudGuardia', () => {
  it('exige bicicleteroId UUID y tipo válido', () => {
    expect(
      esValido(esquemaCrearSolicitudGuardia, {
        bicicleteroId: UUID,
        tipo: TipoSolicitudGuardia.GUARDIA_AUSENTE
      })
    ).toBe(true);
    expect(esValido(esquemaCrearSolicitudGuardia, { bicicleteroId: UUID, tipo: 'INVENTADO' })).toBe(
      false
    );
  });
});

describe('esquemas de solicitudes de guardia', () => {
  it('actualizacion de estado exige estado valido', () => {
    expect(
      esValido(esquemaActualizarEstadoSolicitudGuardia, {
        estado: EstadoSolicitudGuardia.EN_CAMINO
      })
    ).toBe(true);
    expect(esValido(esquemaActualizarEstadoSolicitudGuardia, { estado: 'EN_PAUSA' })).toBe(false);
    expect(esValido(esquemaActualizarEstadoSolicitudGuardia, {})).toBe(false);
  });

  it('notificar guardia acepta body vacio y limita mensaje', () => {
    const { error, value } = esquemaNotificarGuardiaSolicitud.validate(undefined);
    expect(error).toBeUndefined();
    expect(value).toEqual({});
    expect(esValido(esquemaNotificarGuardiaSolicitud, { mensaje: 'Recordatorio' })).toBe(true);
    expect(esValido(esquemaNotificarGuardiaSolicitud, { mensaje: 'x'.repeat(601) })).toBe(false);
  });
});

describe('esquemaSeleccionarBicicleteroGuardia', () => {
  it('exige bicicleteroId UUID', () => {
    expect(esValido(esquemaSeleccionarBicicleteroGuardia, { bicicleteroId: UUID })).toBe(true);
    expect(esValido(esquemaSeleccionarBicicleteroGuardia, { bicicleteroId: 'no-uuid' })).toBe(
      false
    );
    expect(esValido(esquemaSeleccionarBicicleteroGuardia, {})).toBe(false);
  });
});
