import bcrypt from 'bcryptjs';
import { ErrorHttp } from '../../../comun/errors/error-http';
import { entorno } from '../../../configuracion/entorno';
import { prisma, type ClientePrisma } from '../../../configuracion/prisma';
import { Prisma } from '../../../generated/prisma/client';
import { registrarAuditoria } from '../../auditoria/auditoria.servicio';
import {
  crearCorreoCompletarRegistro,
  crearCorreoMovimientoManual,
  enviarCorreo
} from '../../correos/correo.servicio';
import { EstadoMovimiento } from '../../historial/estado-movimiento';
import { TipoMovimiento } from '../../historial/tipo-movimiento';
import { crearNotificacion } from '../../notificaciones/notificacion.servicio';
import { TipoNotificacion } from '../../notificaciones/tipo-notificacion';
import { obtenerCodigoQrEscaneadoParaMovimiento } from '../../qr/qr.servicio';
import { RolUsuario } from '../../usuarios/rol-usuario';
import {
  crearTokenSeguro,
  hashearToken,
  horasExpiracionVerificacionCorreo,
  resolverRolRegistrable
} from '../../autenticacion/autenticacion.tokens';
import { includeMovimientoCompleto, mapearMovimiento } from './acceso.mapeador';
import { validarReglaMovimiento } from './acceso.reglas';

type DatosConfirmarQr = {
  token: string;
  guardiaId: string;
  rol: string;
  bicicleteroId?: string;
  comentario?: string | null;
};

type DatosDenegarQr = DatosConfirmarQr & {
  motivo: string;
};

type DatosGestionManual = {
  guardiaId: string;
  rol: string;
  correo?: string;
  rut?: string;
  bicicletaId?: string;
  bicicletaDescripcion?: string;
  bicicletaMarca?: string | null;
  bicicletaModelo?: string | null;
  bicicletaColor?: string | null;
  bicicletaAro?: string | null;
  bicicletaNumeroSerie?: string | null;
  bicicleteroId?: string;
  tipo: TipoMovimiento;
  denegar?: boolean;
  motivo?: string | null;
  comentario?: string | null;
};

type DatosBuscarGestionManual = {
  correo?: string;
  rut?: string;
};

type UsuarioOperacion = Prisma.UsuarioGetPayload<Record<string, never>>;
type BicicleteroOperacion = Prisma.BicicleteroGetPayload<Record<string, never>>;
type BicicletaOperacion = Prisma.BicicletaGetPayload<{
  include: {
    bicicleteroActual: true;
  };
}>;

const limpiarRut = (rut: string) => rut.replace(/\./g, '').replace('-', '').toUpperCase();

const formatearRutConPuntos = (rutLimpio: string) => {
  if (!/^\d{7,8}[0-9K]$/.test(rutLimpio)) {
    return null;
  }

  const cuerpo = rutLimpio.slice(0, -1);
  const dv = rutLimpio.slice(-1);
  const cuerpoFormateado = cuerpo.replace(/\B(?=(\d{3})+(?!\d))/g, '.');
  return `${cuerpoFormateado}-${dv}`;
};

const obtenerVariantesRut = (rut?: string) => {
  const original = rut?.trim();
  if (!original) {
    return [];
  }

  const limpio = limpiarRut(original);
  const sinPuntos = limpio.length > 1 ? `${limpio.slice(0, -1)}-${limpio.slice(-1)}` : limpio;
  const conPuntos = formatearRutConPuntos(limpio);

  return [
    ...new Set([original, original.toUpperCase(), limpio, sinPuntos, conPuntos].filter(Boolean))
  ];
};

const construirCriteriosUsuarioManual = ({ correo, rut }: DatosBuscarGestionManual) => {
  const criterios: Prisma.UsuarioWhereInput[] = [];
  const correoNormalizado = correo?.trim().toLowerCase();

  if (correoNormalizado) {
    criterios.push({ correo: correoNormalizado });
  }

  for (const varianteRut of obtenerVariantesRut(rut)) {
    criterios.push({ rut: varianteRut });
  }

  return criterios;
};

const mapearBicicletaManual = (
  bicicleta: Prisma.BicicletaGetPayload<{ include: { bicicleteroActual: true } }>
) => ({
  id: bicicleta.id,
  descripcion: bicicleta.descripcion,
  marca: bicicleta.marca,
  modelo: bicicleta.modelo,
  color: bicicleta.color,
  aro: bicicleta.aro,
  numeroSerie: bicicleta.numeroSerie,
  fotoUrl: bicicleta.fotoUrl,
  activa: bicicleta.activa,
  dentroBicicletero: bicicleta.dentroBicicletero,
  bicicleteroActual: bicicleta.bicicleteroActual
    ? {
        id: bicicleta.bicicleteroActual.id,
        nombre: bicicleta.bicicleteroActual.nombre,
        ubicacion: bicicleta.bicicleteroActual.ubicacion
      }
    : null
});

const obtenerBicicleteroOperacion = async (
  guardiaId: string,
  rol: string,
  bicicleteroId?: string,
  bicicleteroQr?: BicicleteroOperacion | null,
  db: ClientePrisma = prisma
) => {
  const validarAsignacionGuardia = async (bicicletero: BicicleteroOperacion) => {
    if (rol !== RolUsuario.GUARDIA) {
      return;
    }

    const asignacion = await db.asignacionGuardia.findFirst({
      where: {
        guardiaId,
        bicicleteroId: bicicletero.id,
        activa: true
      }
    });

    if (!asignacion) {
      throw new ErrorHttp(403, 'El guardia no está asignado a este bicicletero');
    }
  };

  if (bicicleteroId) {
    const bicicletero = await db.bicicletero.findUnique({
      where: {
        id: bicicleteroId
      }
    });

    if (!bicicletero) {
      throw new ErrorHttp(404, 'Bicicletero no encontrado');
    }

    await validarAsignacionGuardia(bicicletero);
    return bicicletero;
  }

  if (bicicleteroQr) {
    await validarAsignacionGuardia(bicicleteroQr);
    return bicicleteroQr;
  }

  const asignacion = await db.asignacionGuardia.findFirst({
    where: {
      guardiaId,
      activa: true
    },
    include: {
      bicicletero: true
    },
    orderBy: {
      iniciaEn: 'desc'
    }
  });

  if (!asignacion) {
    throw new ErrorHttp(400, 'Debes indicar bicicletero para esta operación');
  }

  return asignacion.bicicletero;
};

const registrarMovimiento = async ({
  usuario,
  bicicleta,
  bicicletero,
  guardiaId,
  tipo,
  estado,
  origen,
  motivo,
  comentario,
  db
}: {
  usuario: UsuarioOperacion;
  bicicleta: BicicletaOperacion;
  bicicletero: BicicleteroOperacion;
  guardiaId: string;
  tipo: TipoMovimiento;
  estado: EstadoMovimiento;
  origen: 'QR' | 'MANUAL';
  motivo?: string | null;
  comentario?: string | null;
  db: ClientePrisma;
}) => {
  const comentarioGuardia = comentario?.trim() || null;
  const movimiento = await db.movimiento.create({
    data: {
      usuarioId: usuario.id,
      bicicletaId: bicicleta.id,
      bicicleteroId: bicicletero.id,
      validadoPorGuardiaId: guardiaId,
      tipo,
      estado,
      origen,
      motivoDenegacion: motivo ?? null,
      comentarioGuardia
    }
  });

  if (estado === EstadoMovimiento.CONFIRMADO) {
    await db.bicicleta.update({
      where: {
        id: bicicleta.id
      },
      data:
        tipo === TipoMovimiento.INGRESO
          ? {
              dentroBicicletero: true,
              bicicleteroActualId: bicicletero.id
            }
          : {
              dentroBicicletero: false,
              bicicleteroActualId: null
            }
    });
  }

  const etiquetaMovimiento = tipo === TipoMovimiento.INGRESO ? 'Ingreso' : 'Retiro';
  const mensajeConfirmado =
    tipo === TipoMovimiento.INGRESO
      ? `${bicicleta.descripcion} fue registrada en ${bicicletero.nombre}.`
      : `${bicicleta.descripcion} fue registrada como retirada de ${bicicletero.nombre}.`;
  const mensajeDenegado = motivo
    ? `El guardia denegó la operación. Motivo: ${motivo}.`
    : 'El guardia denegó la operación.';

  await crearNotificacion(
    {
      usuarioId: usuario.id,
      titulo:
        estado === EstadoMovimiento.CONFIRMADO
          ? `${etiquetaMovimiento} confirmado`
          : `${etiquetaMovimiento} denegado`,
      mensaje: estado === EstadoMovimiento.CONFIRMADO ? mensajeConfirmado : mensajeDenegado,
      tipo: TipoNotificacion.MOVIMIENTO,
      datos: {
        movimientoId: movimiento.id,
        estado,
        tipo
      }
    },
    db
  );

  await registrarAuditoria(
    {
      actorUsuarioId: guardiaId,
      accion:
        estado === EstadoMovimiento.CONFIRMADO ? 'MOVIMIENTO_CONFIRMADO' : 'MOVIMIENTO_DENEGADO',
      entidad: 'movimientos',
      entidadId: movimiento.id,
      datos: {
        usuarioId: usuario.id,
        bicicletaId: bicicleta.id,
        bicicleteroId: bicicletero.id,
        tipo,
        estado,
        origen,
        comentarioGuardia
      }
    },
    db
  );

  const movimientoCompleto = await db.movimiento.findUniqueOrThrow({
    where: {
      id: movimiento.id
    },
    include: includeMovimientoCompleto
  });

  if (origen === 'MANUAL') {
    const correo = crearCorreoMovimientoManual({
      nombre: movimientoCompleto.usuario.nombre,
      tipo: movimientoCompleto.tipo,
      estado: movimientoCompleto.estado,
      bicicleta: movimientoCompleto.bicicleta.descripcion,
      bicicletero: movimientoCompleto.bicicletero.nombre,
      guardia: movimientoCompleto.validadoPorGuardia.nombre,
      fecha: movimientoCompleto.creadoEn,
      motivoDenegacion: movimientoCompleto.motivoDenegacion,
      comentarioGuardia: movimientoCompleto.comentarioGuardia
    });

    await enviarCorreo({
      para: movimientoCompleto.usuario.correo,
      asunto: correo.asunto,
      texto: correo.texto,
      html: correo.html
    });
  }

  return mapearMovimiento(movimientoCompleto);
};

const crearBicicletaManual = async (
  db: ClientePrisma,
  usuarioId: string,
  datos: DatosGestionManual
) => {
  const descripcion = datos.bicicletaDescripcion?.trim();

  if (!descripcion) {
    throw new ErrorHttp(400, 'Debes indicar los datos de la bicicleta para el ingreso manual');
  }

  await db.bicicleta.updateMany({
    where: {
      usuarioId,
      eliminadoEn: null
    },
    data: {
      activa: false
    }
  });

  return db.bicicleta.create({
    data: {
      usuarioId,
      descripcion,
      marca: datos.bicicletaMarca || null,
      modelo: datos.bicicletaModelo || null,
      color: datos.bicicletaColor || null,
      aro: datos.bicicletaAro || null,
      numeroSerie: datos.bicicletaNumeroSerie || null,
      activa: true,
      dentroBicicletero: false,
      bicicleteroActualId: null
    },
    include: {
      bicicleteroActual: true
    }
  });
};

const enviarCorreoCompletarRegistro = async (correoUsuario: string, token: string) => {
  const enlace = `${entorno.app.urlFrontend}/completar-registro?token=${token}`;
  const correo = crearCorreoCompletarRegistro(correoUsuario, enlace);

  await enviarCorreo({
    para: correoUsuario,
    asunto: correo.asunto,
    texto: correo.texto,
    html: correo.html
  });
};

export const confirmarQr = async (datos: DatosConfirmarQr) => {
  return prisma.$transaction(async (db) => {
    const codigo = await obtenerCodigoQrEscaneadoParaMovimiento(
      datos.token,
      {
        validadorUsuarioId: datos.guardiaId,
        rol: datos.rol
      },
      db
    );
    const bicicletero = await obtenerBicicleteroOperacion(
      datos.guardiaId,
      datos.rol,
      datos.bicicleteroId,
      codigo.bicicletero ?? codigo.bicicleta.bicicleteroActual,
      db
    );
    const tipo = codigo.tipo as TipoMovimiento;

    validarReglaMovimiento(codigo.bicicleta, tipo);

    const marcado = await db.codigoQrTemporal.updateMany({
      where: {
        id: codigo.id,
        usado: false
      },
      data: {
        usado: true
      }
    });

    if (marcado.count !== 1) {
      throw new ErrorHttp(409, 'QR ya fue usado o reemplazado');
    }

    return registrarMovimiento({
      usuario: codigo.usuario,
      bicicleta: codigo.bicicleta,
      bicicletero,
      guardiaId: datos.guardiaId,
      tipo,
      estado: EstadoMovimiento.CONFIRMADO,
      origen: 'QR',
      comentario: datos.comentario,
      db
    });
  });
};

export const denegarQr = async (datos: DatosDenegarQr) => {
  return prisma.$transaction(async (db) => {
    const codigo = await obtenerCodigoQrEscaneadoParaMovimiento(
      datos.token,
      {
        validadorUsuarioId: datos.guardiaId,
        rol: datos.rol
      },
      db
    );
    const bicicletero = await obtenerBicicleteroOperacion(
      datos.guardiaId,
      datos.rol,
      datos.bicicleteroId,
      codigo.bicicletero ?? codigo.bicicleta.bicicleteroActual,
      db
    );
    const tipo = codigo.tipo as TipoMovimiento;

    const marcado = await db.codigoQrTemporal.updateMany({
      where: {
        id: codigo.id,
        usado: false
      },
      data: {
        usado: true
      }
    });

    if (marcado.count !== 1) {
      throw new ErrorHttp(409, 'QR ya fue usado o reemplazado');
    }

    return registrarMovimiento({
      usuario: codigo.usuario,
      bicicleta: codigo.bicicleta,
      bicicletero,
      guardiaId: datos.guardiaId,
      tipo,
      estado: EstadoMovimiento.DENEGADO,
      origen: 'QR',
      motivo: datos.motivo,
      db
    });
  });
};

export const buscarCoincidenciaGestionManual = async (datos: DatosBuscarGestionManual) => {
  const criteriosUsuario = construirCriteriosUsuarioManual(datos);

  if (!criteriosUsuario.length) {
    throw new ErrorHttp(400, 'Debes indicar correo o RUT para buscar coincidencias');
  }

  const usuario = await prisma.usuario.findFirst({
    where: {
      OR: criteriosUsuario
    },
    include: {
      bicicletas: {
        where: {
          eliminadoEn: null
        },
        include: {
          bicicleteroActual: true
        },
        orderBy: [{ activa: 'desc' }, { dentroBicicletero: 'desc' }, { creadoEn: 'desc' }]
      }
    }
  });

  if (!usuario) {
    return null;
  }

  return {
    usuario: {
      id: usuario.id,
      nombre: usuario.nombre,
      correo: usuario.correo,
      rut: usuario.rut,
      rol: usuario.rol,
      correoVerificado: usuario.correoVerificado,
      registroParcial: usuario.registroParcial,
      cuentaActiva: usuario.cuentaActiva
    },
    bicicletas: usuario.bicicletas.map(mapearBicicletaManual)
  };
};

export const registrarGestionManual = async (datos: DatosGestionManual) => {
  let tokenCompletarRegistro: string | null = null;
  let correoCompletarRegistro: string | null = null;

  const movimiento = await prisma.$transaction(async (db) => {
    const criteriosUsuario = construirCriteriosUsuarioManual(datos);

    if (!criteriosUsuario.length) {
      throw new ErrorHttp(400, 'Debes indicar correo o RUT');
    }

    let usuario = await db.usuario.findFirst({
      where: {
        OR: criteriosUsuario
      }
    });

    if (!usuario) {
      if (!datos.correo || !datos.rut) {
        throw new ErrorHttp(
          400,
          'Para registrar un usuario nuevo debes indicar correo institucional y RUT'
        );
      }

      if (datos.tipo !== TipoMovimiento.INGRESO) {
        throw new ErrorHttp(404, 'Usuario no encontrado para registrar retiro manual');
      }

      const correoNormalizado = datos.correo.toLowerCase();
      const rolAsignado = resolverRolRegistrable(correoNormalizado);
      tokenCompletarRegistro = crearTokenSeguro();
      correoCompletarRegistro = correoNormalizado;

      usuario = await db.usuario.create({
        data: {
          nombre: 'Registro pendiente',
          correo: correoNormalizado,
          rut: datos.rut,
          rol: rolAsignado,
          contrasenaHash: await bcrypt.hash(crearTokenSeguro(), 12),
          cuentaActiva: true,
          correoVerificado: false,
          registroParcial: true,
          tokenVerificacionCorreo: hashearToken(tokenCompletarRegistro),
          tokenVerificacionCorreoExpiraEn: new Date(
            Date.now() + 1000 * 60 * 60 * horasExpiracionVerificacionCorreo
          )
        }
      });
    } else if (usuario.registroParcial) {
      if (datos.tipo === TipoMovimiento.RETIRO) {
        throw new ErrorHttp(
          409,
          'El usuario debe completar su registro (revisa el correo de activación) antes de retirar la bicicleta.'
        );
      }

      tokenCompletarRegistro = crearTokenSeguro();
      correoCompletarRegistro = usuario.correo;

      usuario = await db.usuario.update({
        where: {
          id: usuario.id
        },
        data: {
          tokenVerificacionCorreo: hashearToken(tokenCompletarRegistro),
          tokenVerificacionCorreoExpiraEn: new Date(
            Date.now() + 1000 * 60 * 60 * horasExpiracionVerificacionCorreo
          )
        }
      });
    }

    let bicicleta = await db.bicicleta.findFirst({
      where: datos.bicicletaId
        ? {
            id: datos.bicicletaId,
            usuarioId: usuario.id,
            eliminadoEn: null
          }
        : {
            usuarioId: usuario.id,
            activa: true,
            eliminadoEn: null
          },
      include: {
        bicicleteroActual: true
      }
    });

    if (!bicicleta) {
      if (datos.tipo !== TipoMovimiento.INGRESO) {
        throw new ErrorHttp(404, 'Bicicleta activa no encontrada para el usuario');
      }

      bicicleta = await crearBicicletaManual(db, usuario.id, datos);
    }

    const bicicletero = await obtenerBicicleteroOperacion(
      datos.guardiaId,
      datos.rol,
      datos.bicicleteroId,
      bicicleta.bicicleteroActual,
      db
    );

    const estado = datos.denegar ? EstadoMovimiento.DENEGADO : EstadoMovimiento.CONFIRMADO;

    if (estado === EstadoMovimiento.CONFIRMADO) {
      validarReglaMovimiento(bicicleta, datos.tipo);
    }

    return registrarMovimiento({
      usuario,
      bicicleta,
      bicicletero,
      guardiaId: datos.guardiaId,
      tipo: datos.tipo,
      estado,
      origen: 'MANUAL',
      motivo: datos.motivo,
      comentario: datos.comentario,
      db
    });
  });

  if (tokenCompletarRegistro && correoCompletarRegistro) {
    await enviarCorreoCompletarRegistro(correoCompletarRegistro, tokenCompletarRegistro);
  }

  return movimiento;
};
