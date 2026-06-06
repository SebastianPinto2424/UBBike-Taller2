import crypto from 'crypto';
import { ErrorHttp } from '../../comun/errors/error-http';
import { entorno } from '../../configuracion/entorno';
import { prisma, type ClientePrisma } from '../../configuracion/prisma';
import type {
  Bicicleta,
  Bicicletero,
  CodigoQrTemporal,
  Usuario
} from '../../generated/prisma/client';
import { TipoMovimiento } from '../historial/tipo-movimiento';
import { RolUsuario } from '../usuarios/rol-usuario';

const duracionQrSegundos = entorno.qr.duracionSegundos;

type DatosGenerarQr = {
  usuarioId: string;
  bicicletaId?: string;
  bicicleteroId?: string;
  tipo?: TipoMovimiento;
};

type ContextoValidacionQr = {
  validadorUsuarioId: string;
  rol: string;
};

type BicicletaConBicicleteroActual = Bicicleta & {
  bicicleteroActual: Bicicletero | null;
};

type CodigoQrCompleto = CodigoQrTemporal & {
  usuario: Usuario;
  bicicleta: BicicletaConBicicleteroActual;
  bicicletero: Bicicletero | null;
};

const buscarBicicletaParaQr = async (usuarioId: string, bicicletaId?: string) => {
  const where = bicicletaId
    ? {
        id: bicicletaId,
        usuarioId,
        eliminadoEn: null
      }
    : {
        activa: true,
        usuarioId,
        eliminadoEn: null
      };

  const bicicleta = await prisma.bicicleta.findFirst({
    where,
    include: {
      usuario: true,
      bicicleteroActual: true
    }
  });

  if (!bicicleta) {
    throw new ErrorHttp(
      404,
      bicicletaId ? 'Bicicleta no encontrada' : 'Debes activar una bicicleta antes de generar el QR'
    );
  }

  return bicicleta;
};

export const generarQrTemporal = async (datos: DatosGenerarQr) => {
  const bicicleta = await buscarBicicletaParaQr(datos.usuarioId, datos.bicicletaId);
  const tipo =
    datos.tipo ?? (bicicleta.dentroBicicletero ? TipoMovimiento.RETIRO : TipoMovimiento.INGRESO);
  const bicicletero = datos.bicicleteroId
    ? await prisma.bicicletero.findUnique({ where: { id: datos.bicicleteroId } })
    : bicicleta.bicicleteroActual;

  if (datos.bicicleteroId && !bicicletero) {
    throw new ErrorHttp(404, 'Bicicletero no encontrado');
  }

  if (tipo === TipoMovimiento.INGRESO && !bicicletero) {
    throw new ErrorHttp(400, 'Selecciona un bicicletero para generar QR de ingreso');
  }

  if (tipo === TipoMovimiento.RETIRO && !bicicleta.dentroBicicletero) {
    throw new ErrorHttp(409, 'La bicicleta no registra ingreso activo');
  }

  if (tipo === TipoMovimiento.INGRESO && bicicleta.dentroBicicletero) {
    throw new ErrorHttp(409, 'La bicicleta ya registra ingreso activo');
  }

  const token = `UBBIKE-${crypto.randomBytes(24).toString('base64url')}`;
  const expiraEn = new Date(Date.now() + duracionQrSegundos * 1000);
  const codigo = await prisma.$transaction(async (tx) => {
    await tx.codigoQrTemporal.updateMany({
      where: {
        usuarioId: datos.usuarioId,
        usado: false
      },
      data: {
        usado: true
      }
    });

    return tx.codigoQrTemporal.create({
      data: {
        token,
        usuarioId: datos.usuarioId,
        bicicletaId: bicicleta.id,
        bicicleteroId: bicicletero?.id ?? null,
        tipo,
        expiraEn,
        usado: false
      }
    });
  });

  return {
    id: codigo.id,
    token: codigo.token,
    tipo: codigo.tipo,
    duracionSegundos: duracionQrSegundos,
    expiraEn: codigo.expiraEn,
    bicicleta: {
      id: bicicleta.id,
      descripcion: bicicleta.descripcion,
      marca: bicicleta.marca,
      modelo: bicicleta.modelo,
      color: bicicleta.color,
      aro: bicicleta.aro,
      numeroSerie: bicicleta.numeroSerie,
      fotoUrl: bicicleta.fotoUrl
    },
    bicicletero: bicicletero
      ? {
          id: bicicletero.id,
          nombre: bicicletero.nombre
        }
      : null
  };
};

const validarBicicleteroGuardia = async (
  codigo: CodigoQrCompleto,
  contexto?: ContextoValidacionQr
) => {
  if (contexto?.rol !== RolUsuario.GUARDIA) {
    return;
  }

  const bicicleteroQr = codigo.bicicletero ?? codigo.bicicleta.bicicleteroActual;

  if (!bicicleteroQr) {
    throw new ErrorHttp(400, 'El QR no tiene bicicletero asociado');
  }

  const asignacion = await prisma.asignacionGuardia.findFirst({
    where: {
      guardiaId: contexto.validadorUsuarioId,
      bicicleteroId: bicicleteroQr.id,
      activa: true
    }
  });

  if (!asignacion) {
    throw new ErrorHttp(403, 'El QR corresponde a otro bicicletero o no está asignado a tu turno');
  }
};

export const validarQrTemporal = async (token: string, contexto?: ContextoValidacionQr) => {
  const codigo = await obtenerCodigoQrValido(token);
  await validarBicicleteroGuardia(codigo, contexto);

  if (contexto) {
    const marcado = await prisma.codigoQrTemporal.updateMany({
      where: {
        id: codigo.id,
        usado: false,
        OR: [
          { escaneadoPorGuardiaId: null },
          { escaneadoPorGuardiaId: contexto.validadorUsuarioId }
        ]
      },
      data: {
        escaneadoPorGuardiaId: contexto.validadorUsuarioId,
        escaneadoEn: new Date()
      }
    });

    if (marcado.count !== 1) {
      throw new ErrorHttp(409, 'QR ya fue tomado por otro validador');
    }
  }

  return {
    valido: true,
    token: codigo.token,
    tipo: codigo.tipo,
    expiraEn: codigo.expiraEn,
    usuario: {
      id: codigo.usuario.id,
      nombre: codigo.usuario.nombre,
      correo: codigo.usuario.correo,
      rut: codigo.usuario.rut
    },
    bicicleta: {
      id: codigo.bicicleta.id,
      descripcion: codigo.bicicleta.descripcion,
      marca: codigo.bicicleta.marca,
      modelo: codigo.bicicleta.modelo,
      color: codigo.bicicleta.color,
      aro: codigo.bicicleta.aro,
      numeroSerie: codigo.bicicleta.numeroSerie,
      fotoUrl: codigo.bicicleta.fotoUrl
    },
    bicicletero: codigo.bicicletero
      ? {
          id: codigo.bicicletero.id,
          nombre: codigo.bicicletero.nombre
        }
      : null
  };
};

export const obtenerCodigoQrValido = async (
  token: string,
  db: ClientePrisma = prisma
): Promise<CodigoQrCompleto> => {
  const codigo = await db.codigoQrTemporal.findFirst({
    where: {
      token
    },
    include: {
      usuario: true,
      bicicleta: {
        include: {
          bicicleteroActual: true
        }
      },
      bicicletero: true
    }
  });

  if (!codigo) {
    throw new ErrorHttp(404, 'QR no encontrado');
  }

  if (codigo.usado) {
    throw new ErrorHttp(409, 'QR ya fue usado o reemplazado');
  }

  if (codigo.expiraEn.getTime() < Date.now()) {
    throw new ErrorHttp(410, 'QR expirado. Debe regenerarse');
  }

  return codigo;
};

export const obtenerCodigoQrEscaneadoParaMovimiento = async (
  token: string,
  contexto: ContextoValidacionQr,
  db: ClientePrisma = prisma
): Promise<CodigoQrCompleto> => {
  const codigo = await db.codigoQrTemporal.findFirst({
    where: {
      token
    },
    include: {
      usuario: true,
      bicicleta: {
        include: {
          bicicleteroActual: true
        }
      },
      bicicletero: true
    }
  });

  if (!codigo) {
    throw new ErrorHttp(404, 'QR no encontrado');
  }

  if (codigo.usado) {
    throw new ErrorHttp(409, 'QR ya fue usado o reemplazado');
  }

  if (!codigo.escaneadoPorGuardiaId) {
    throw new ErrorHttp(409, 'Debes validar el QR antes de confirmar o denegar');
  }

  if (codigo.escaneadoPorGuardiaId !== contexto.validadorUsuarioId) {
    throw new ErrorHttp(409, 'QR ya fue tomado por otro validador');
  }

  await validarBicicleteroGuardia(codigo, contexto);

  return codigo;
};
