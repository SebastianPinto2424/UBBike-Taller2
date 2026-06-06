import { ErrorHttp } from '../../comun/errors/error-http';
import { prisma } from '../../configuracion/prisma';
import type { Bicicleta } from '../../generated/prisma/client';
import { eliminarArchivoFotoBicicleta, guardarFotoBicicleta } from './foto-bicicleta.servicio';

type DatosCrearBicicleta = {
  usuarioId: string;
  descripcion: string;
  marca?: string | null;
  modelo?: string | null;
  color?: string | null;
  aro?: string | null;
  numeroSerie?: string | null;
  fotoUrl?: string | null;
  activar?: boolean;
};

type DatosActualizarBicicleta = {
  descripcion?: string;
  marca?: string | null;
  modelo?: string | null;
  color?: string | null;
  aro?: string | null;
  numeroSerie?: string | null;
  fotoUrl?: string | null;
};

const esFotoNueva = (fotoUrl?: string | null) => fotoUrl?.startsWith('data:image') === true;

const mapearBicicleta = (
  bicicleta: Bicicleta & { bicicleteroActual?: { id: string; nombre: string } | null }
) => ({
  id: bicicleta.id,
  descripcion: bicicleta.descripcion,
  marca: bicicleta.marca,
  modelo: bicicleta.modelo,
  color: bicicleta.color,
  aro: bicicleta.aro,
  numeroSerie: bicicleta.numeroSerie,
  fotoUrl: bicicleta.fotoUrl,
  fotoNombreArchivo: bicicleta.fotoNombreArchivo,
  fotoMimeType: bicicleta.fotoMimeType,
  fotoTamanoBytes: bicicleta.fotoTamanoBytes,
  fotoActualizadaEn: bicicleta.fotoActualizadaEn,
  activa: bicicleta.activa,
  dentroBicicletero: bicicleta.dentroBicicletero,
  bicicleteroActual: bicicleta.bicicleteroActual
    ? {
        id: bicicleta.bicicleteroActual.id,
        nombre: bicicleta.bicicleteroActual.nombre
      }
    : null,
  creadoEn: bicicleta.creadoEn,
  actualizadoEn: bicicleta.actualizadoEn
});

const buscarBicicletaUsuario = async (usuarioId: string, bicicletaId: string) => {
  const bicicleta = await prisma.bicicleta.findFirst({
    where: {
      id: bicicletaId,
      usuarioId,
      eliminadoEn: null
    },
    include: {
      bicicleteroActual: {
        select: {
          id: true,
          nombre: true
        }
      }
    }
  });

  if (!bicicleta) {
    throw new ErrorHttp(404, 'Bicicleta no encontrada');
  }

  return bicicleta;
};

const dejarSoloActiva = async (usuarioId: string, bicicletaId: string) => {
  await prisma.bicicleta.updateMany({
    where: {
      usuarioId,
      eliminadoEn: null
    },
    data: {
      activa: false
    }
  });

  await prisma.bicicleta.update({
    where: {
      id: bicicletaId
    },
    data: {
      activa: true
    }
  });
};

export const listarBicicletasUsuario = async (usuarioId: string) => {
  const bicicletas = await prisma.bicicleta.findMany({
    where: {
      usuarioId,
      eliminadoEn: null
    },
    include: {
      bicicleteroActual: {
        select: {
          id: true,
          nombre: true
        }
      }
    },
    orderBy: [{ activa: 'desc' }, { actualizadoEn: 'desc' }]
  });

  return bicicletas.map(mapearBicicleta);
};

export const obtenerBicicletaActivaUsuario = async (usuarioId: string) => {
  const bicicleta = await prisma.bicicleta.findFirst({
    where: {
      usuarioId,
      activa: true,
      eliminadoEn: null
    },
    include: {
      bicicleteroActual: {
        select: {
          id: true,
          nombre: true
        }
      }
    }
  });

  return bicicleta ? mapearBicicleta(bicicleta) : null;
};

export const crearBicicleta = async (datos: DatosCrearBicicleta) => {
  const fotoGuardada = esFotoNueva(datos.fotoUrl)
    ? await guardarFotoBicicleta('bicicleta', datos.fotoUrl!)
    : null;

  const totalBicicletas = await prisma.bicicleta.count({
    where: {
      usuarioId: datos.usuarioId,
      eliminadoEn: null
    }
  });

  const debeActivar = totalBicicletas === 0 || datos.activar === true;

  const guardada = await prisma.bicicleta.create({
    data: {
      usuarioId: datos.usuarioId,
      descripcion: datos.descripcion,
      marca: datos.marca || null,
      modelo: datos.modelo || null,
      color: datos.color || null,
      aro: datos.aro || null,
      numeroSerie: datos.numeroSerie || null,
      fotoUrl: fotoGuardada?.fotoUrl ?? null,
      fotoNombreArchivo: fotoGuardada?.fotoNombreArchivo ?? null,
      fotoMimeType: fotoGuardada?.fotoMimeType ?? null,
      fotoTamanoBytes: fotoGuardada?.fotoTamanoBytes ?? null,
      fotoActualizadaEn: fotoGuardada?.fotoActualizadaEn ?? null,
      activa: false,
      dentroBicicletero: false,
      bicicleteroActualId: null
    }
  });

  if (debeActivar) {
    await dejarSoloActiva(datos.usuarioId, guardada.id);
  }

  const actualizada = await buscarBicicletaUsuario(datos.usuarioId, guardada.id);
  return mapearBicicleta(actualizada);
};

export const actualizarBicicleta = async (
  usuarioId: string,
  bicicletaId: string,
  datos: DatosActualizarBicicleta
) => {
  const bicicleta = await buscarBicicletaUsuario(usuarioId, bicicletaId);

  if (datos.descripcion !== undefined) {
    bicicleta.descripcion = datos.descripcion;
  }

  if (datos.marca !== undefined) {
    bicicleta.marca = datos.marca || null;
  }

  if (datos.modelo !== undefined) {
    bicicleta.modelo = datos.modelo || null;
  }

  if (datos.color !== undefined) {
    bicicleta.color = datos.color || null;
  }

  if (datos.aro !== undefined) {
    bicicleta.aro = datos.aro || null;
  }

  if (datos.numeroSerie !== undefined) {
    bicicleta.numeroSerie = datos.numeroSerie || null;
  }

  if (datos.fotoUrl !== undefined) {
    if (!datos.fotoUrl) {
      await eliminarArchivoFotoBicicleta(bicicleta.fotoNombreArchivo);
      bicicleta.fotoUrl = null;
      bicicleta.fotoNombreArchivo = null;
      bicicleta.fotoMimeType = null;
      bicicleta.fotoTamanoBytes = null;
      bicicleta.fotoActualizadaEn = null;
    } else if (esFotoNueva(datos.fotoUrl)) {
      const fotoGuardada = await guardarFotoBicicleta(bicicleta.id, datos.fotoUrl);
      await eliminarArchivoFotoBicicleta(bicicleta.fotoNombreArchivo);
      bicicleta.fotoUrl = fotoGuardada.fotoUrl;
      bicicleta.fotoNombreArchivo = fotoGuardada.fotoNombreArchivo;
      bicicleta.fotoMimeType = fotoGuardada.fotoMimeType;
      bicicleta.fotoTamanoBytes = fotoGuardada.fotoTamanoBytes;
      bicicleta.fotoActualizadaEn = fotoGuardada.fotoActualizadaEn;
    }
  }

  const guardada = await prisma.bicicleta.update({
    where: {
      id: bicicleta.id
    },
    data: {
      descripcion: bicicleta.descripcion,
      marca: bicicleta.marca,
      modelo: bicicleta.modelo,
      color: bicicleta.color,
      aro: bicicleta.aro,
      numeroSerie: bicicleta.numeroSerie,
      fotoUrl: bicicleta.fotoUrl,
      fotoNombreArchivo: bicicleta.fotoNombreArchivo,
      fotoMimeType: bicicleta.fotoMimeType,
      fotoTamanoBytes: bicicleta.fotoTamanoBytes,
      fotoActualizadaEn: bicicleta.fotoActualizadaEn
    },
    include: {
      bicicleteroActual: {
        select: {
          id: true,
          nombre: true
        }
      }
    }
  });
  return mapearBicicleta(guardada);
};

export const eliminarBicicleta = async (usuarioId: string, bicicletaId: string) => {
  const bicicleta = await buscarBicicletaUsuario(usuarioId, bicicletaId);
  const estabaActiva = bicicleta.activa;

  await prisma.bicicleta.update({
    where: {
      id: bicicleta.id
    },
    data: {
      eliminadoEn: new Date(),
      activa: false
    }
  });

  await eliminarArchivoFotoBicicleta(bicicleta.fotoNombreArchivo);

  if (estabaActiva) {
    const siguiente = await prisma.bicicleta.findFirst({
      where: {
        usuarioId,
        eliminadoEn: null
      },
      orderBy: {
        actualizadoEn: 'desc'
      }
    });

    if (siguiente) {
      await dejarSoloActiva(usuarioId, siguiente.id);
    }
  }

  return {
    message: 'Bicicleta eliminada correctamente'
  };
};

export const activarBicicleta = async (usuarioId: string, bicicletaId: string) => {
  await buscarBicicletaUsuario(usuarioId, bicicletaId);
  await dejarSoloActiva(usuarioId, bicicletaId);
  const bicicleta = await buscarBicicletaUsuario(usuarioId, bicicletaId);
  return mapearBicicleta(bicicleta);
};

export const desactivarBicicleta = async (usuarioId: string, bicicletaId: string) => {
  const bicicleta = await buscarBicicletaUsuario(usuarioId, bicicletaId);
  const guardada = await prisma.bicicleta.update({
    where: {
      id: bicicleta.id
    },
    data: {
      activa: false
    },
    include: {
      bicicleteroActual: {
        select: {
          id: true,
          nombre: true
        }
      }
    }
  });
  return mapearBicicleta(guardada);
};
