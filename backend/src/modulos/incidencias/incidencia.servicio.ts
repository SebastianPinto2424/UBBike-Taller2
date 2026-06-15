import { ErrorHttp } from '../../comun/errors/error-http';
import type { ClientePrisma } from '../../configuracion/prisma';
import { Prisma } from '../../generated/prisma/client';
import { registrarAuditoria } from '../auditoria/auditoria.servicio';
import {
  crearNotificacion,
  notificarUsuariosPorRol
} from '../notificaciones/notificacion.servicio';
import { TipoNotificacion } from '../notificaciones/tipo-notificacion';
import { RolUsuario } from '../usuarios/rol-usuario';
import {
  EventosTiempoReal,
  emitirTiempoReal,
  salaRol
} from '../../tiempo-real/tiempo-real';
import { EstadoIncidencia } from './estado-incidencia';
import * as incidenciaRepositorio from './incidencia.repositorio';
import type { IncidenciaCompleta } from './incidencia.repositorio';
import { TipoIncidencia } from './tipo-incidencia';

type DatosCrearIncidencia = {
  usuarioId: string;
  rol: string;
  bicicleteroId: string;
  bicicletaId?: string | null;
  tipo: TipoIncidencia;
  descripcion: string;
  ip?: string | null;
  userAgent?: string | null;
};

type DatosListarIncidencias = {
  usuarioId: string;
  rol: string;
  estado?: EstadoIncidencia | 'TODOS';
  tipo?: TipoIncidencia | 'TODOS';
  bicicleteroId?: string;
  q?: string;
  cursor?: string;
  limite?: number;
};

type DatosActualizarIncidencia = {
  usuarioId: string;
  rol: string;
  incidenciaId: string;
  estado: EstadoIncidencia;
  respuesta?: string | null;
  ip?: string | null;
  userAgent?: string | null;
};

const rolesCentral: string[] = [RolUsuario.ADMIN_CENTRAL, RolUsuario.ADMINISTRADOR];
const estadosCerradosIncidencia: EstadoIncidencia[] = [
  EstadoIncidencia.RESUELTA,
  EstadoIncidencia.DESCARTADA
];

const etiquetaEstadoIncidencia = (estado: EstadoIncidencia) => {
  switch (estado) {
    case EstadoIncidencia.PENDIENTE:
      return 'pendiente';
    case EstadoIncidencia.EN_REVISION:
      return 'en revisión';
    case EstadoIncidencia.RESUELTA:
      return 'resuelta';
    case EstadoIncidencia.DESCARTADA:
      return 'descartada';
    default:
      return estado;
  }
};

const mapearUsuarioIncidencia = (
  usuario: IncidenciaCompleta['reportadaPorUsuario'] | IncidenciaCompleta['gestionadaPorUsuario']
) => {
  if (!usuario) {
    return null;
  }

  return {
    id: usuario.id,
    nombre: usuario.nombre,
    correo: usuario.correo,
    rut: usuario.rut,
    rol: usuario.rol
  };
};

const mapearIncidencia = (incidencia: IncidenciaCompleta) => ({
  id: incidencia.id,
  tipo: incidencia.tipo,
  descripcion: incidencia.descripcion,
  estado: incidencia.estado,
  respuesta: incidencia.respuesta,
  creadaEn: incidencia.creadaEn,
  actualizadaEn: incidencia.actualizadaEn,
  resueltaEn: incidencia.resueltaEn,
  reportadaPorUsuario: mapearUsuarioIncidencia(incidencia.reportadaPorUsuario),
  gestionadaPorUsuario: mapearUsuarioIncidencia(incidencia.gestionadaPorUsuario),
  bicicletero: {
    id: incidencia.bicicletero.id,
    nombre: incidencia.bicicletero.nombre,
    ubicacion: incidencia.bicicletero.ubicacion
  },
  bicicleta: incidencia.bicicleta
    ? {
        id: incidencia.bicicleta.id,
        descripcion: incidencia.bicicleta.descripcion,
        marca: incidencia.bicicleta.marca,
        modelo: incidencia.bicicleta.modelo,
        color: incidencia.bicicleta.color,
        aro: incidencia.bicicleta.aro,
        numeroSerie: incidencia.bicicleta.numeroSerie,
        fotoUrl: incidencia.bicicleta.fotoUrl,
        activa: incidencia.bicicleta.activa,
        dentroBicicletero: incidencia.bicicleta.dentroBicicletero
      }
    : null
});

const obtenerBicicleterosAsignadosGuardia = async (guardiaId: string, db?: ClientePrisma) => {
  const asignaciones = await incidenciaRepositorio.buscarBicicleterosAsignados(guardiaId, db);

  return asignaciones.map((asignacion) => asignacion.bicicleteroId);
};

const asegurarBicicleteroExiste = async (bicicleteroId: string, db: ClientePrisma) => {
  const bicicletero = await incidenciaRepositorio.buscarBicicletero(bicicleteroId, db);

  if (!bicicletero) {
    throw new ErrorHttp(404, 'Bicicletero no encontrado');
  }

  return bicicletero;
};

const asegurarBicicletaValida = async (
  datos: Pick<DatosCrearIncidencia, 'usuarioId' | 'rol' | 'bicicletaId'>,
  db: ClientePrisma
) => {
  if (!datos.bicicletaId) {
    return null;
  }

  const bicicleta = await incidenciaRepositorio.buscarBicicletaActiva(datos.bicicletaId, db);

  if (!bicicleta) {
    throw new ErrorHttp(404, 'Bicicleta no encontrada');
  }

  const puedeAsociarCualquierBicicleta =
    rolesCentral.includes(datos.rol) || datos.rol === RolUsuario.GUARDIA;

  if (!puedeAsociarCualquierBicicleta && bicicleta.usuarioId !== datos.usuarioId) {
    throw new ErrorHttp(403, 'No puedes asociar una bicicleta de otro usuario');
  }

  return bicicleta;
};

const construirWhereIncidencias = async (filtros: DatosListarIncidencias) => {
  const condiciones: Prisma.IncidenciaWhereInput[] = [];

  if (rolesCentral.includes(filtros.rol)) {
  } else if (filtros.rol === RolUsuario.GUARDIA) {
    const asignados = await obtenerBicicleterosAsignadosGuardia(filtros.usuarioId);
    condiciones.push({
      OR: [
        { reportadaPorUsuarioId: filtros.usuarioId },
        ...(asignados.length ? [{ bicicleteroId: { in: asignados } }] : [])
      ]
    });
  } else {
    condiciones.push({ reportadaPorUsuarioId: filtros.usuarioId });
  }

  if (filtros.estado && filtros.estado !== 'TODOS') {
    if (!Object.values(EstadoIncidencia).includes(filtros.estado as EstadoIncidencia)) {
      throw new ErrorHttp(400, 'Estado de incidencia inválido');
    }
    condiciones.push({ estado: filtros.estado });
  }

  if (filtros.tipo && filtros.tipo !== 'TODOS') {
    if (!Object.values(TipoIncidencia).includes(filtros.tipo as TipoIncidencia)) {
      throw new ErrorHttp(400, 'Tipo de incidencia inválido');
    }
    condiciones.push({ tipo: filtros.tipo });
  }

  if (filtros.bicicleteroId) {
    condiciones.push({ bicicleteroId: filtros.bicicleteroId });
  }

  if (filtros.q) {
    const q = filtros.q.trim();
    condiciones.push({
      OR: [
        { descripcion: { contains: q, mode: 'insensitive' } },
        { respuesta: { contains: q, mode: 'insensitive' } },
        { reportadaPorUsuario: { nombre: { contains: q, mode: 'insensitive' } } },
        { reportadaPorUsuario: { correo: { contains: q, mode: 'insensitive' } } },
        { reportadaPorUsuario: { rut: { contains: q, mode: 'insensitive' } } },
        { bicicletero: { nombre: { contains: q, mode: 'insensitive' } } },
        { bicicleta: { descripcion: { contains: q, mode: 'insensitive' } } },
        { bicicleta: { numeroSerie: { contains: q, mode: 'insensitive' } } }
      ]
    });
  }

  return condiciones.length ? { AND: condiciones } : {};
};

export const crearIncidencia = async (datos: DatosCrearIncidencia) => {
  return incidenciaRepositorio.ejecutarEnTransaccion(async (db) => {
    const bicicletero = await asegurarBicicleteroExiste(datos.bicicleteroId, db);
    if (datos.rol === RolUsuario.GUARDIA) {
      const asignados = await obtenerBicicleterosAsignadosGuardia(datos.usuarioId, db);

      if (!asignados.includes(bicicletero.id)) {
        throw new ErrorHttp(403, 'Solo puedes reportar incidencias de tu bicicletero asignado');
      }
    }

    const bicicleta = await asegurarBicicletaValida(datos, db);
    const incidencia = await incidenciaRepositorio.crear(
      {
        reportadaPorUsuarioId: datos.usuarioId,
        bicicleteroId: bicicletero.id,
        bicicletaId: bicicleta?.id ?? null,
        tipo: datos.tipo,
        descripcion: datos.descripcion
      },
      db
    );

    await crearNotificacion(
      {
        usuarioId: datos.usuarioId,
        titulo: 'Incidencia registrada',
        mensaje: `Tu reporte para ${bicicletero.nombre} quedó pendiente de revisión.`,
        tipo: TipoNotificacion.INCIDENCIA,
        datos: { incidenciaId: incidencia.id, bicicleteroId: bicicletero.id }
      },
      db
    );

    await notificarUsuariosPorRol(
      {
        roles: [RolUsuario.ADMIN_CENTRAL, RolUsuario.ADMINISTRADOR],
        titulo: 'Nueva incidencia reportada',
        mensaje: `Hay un reporte operativo pendiente en ${bicicletero.nombre}.`,
        tipo: TipoNotificacion.INCIDENCIA,
        datos: { incidenciaId: incidencia.id, bicicleteroId: bicicletero.id }
      },
      db
    );

    const asignacion = await incidenciaRepositorio.buscarAsignacionActivaConGuardia(
      bicicletero.id,
      db
    );

    if (asignacion?.guardia.id && asignacion.guardia.id !== datos.usuarioId) {
      await crearNotificacion(
        {
          usuarioId: asignacion.guardia.id,
          titulo: 'Incidencia en tu bicicletero',
          mensaje: `Hay un nuevo reporte operativo en ${bicicletero.nombre}.`,
          tipo: TipoNotificacion.INCIDENCIA,
          datos: { incidenciaId: incidencia.id, bicicleteroId: bicicletero.id }
        },
        db
      );
    }

    await registrarAuditoria(
      {
        actorUsuarioId: datos.usuarioId,
        accion: 'INCIDENCIA_CREADA',
        entidad: 'incidencias',
        entidadId: incidencia.id,
        ip: datos.ip,
        userAgent: datos.userAgent,
        datos: {
          tipo: datos.tipo,
          bicicleteroId: bicicletero.id,
          bicicletaId: bicicleta?.id ?? null
        }
      },
      db
    );

    emitirTiempoReal(
      [
        salaRol(RolUsuario.GUARDIA),
        salaRol(RolUsuario.ADMIN_CENTRAL),
        salaRol(RolUsuario.ADMINISTRADOR)
      ],
      EventosTiempoReal.INCIDENCIA
    );

    return mapearIncidencia(incidencia);
  });
};

const LIMITE_MAX_INCIDENCIAS = 50;
const LIMITE_DEFAULT_INCIDENCIAS = 20;

export const listarIncidencias = async (filtros: DatosListarIncidencias) => {
  const limite = Math.min(filtros.limite ?? LIMITE_DEFAULT_INCIDENCIAS, LIMITE_MAX_INCIDENCIAS);
  const where = await construirWhereIncidencias(filtros);

  const incidencias = await incidenciaRepositorio.listar({
    where,
    take: limite + 1,
    cursor: filtros.cursor
  });

  const hayMas = incidencias.length > limite;
  const items = hayMas ? incidencias.slice(0, limite) : incidencias;
  const nextCursor = hayMas ? items[items.length - 1].id : null;

  return {
    incidencias: items.map(mapearIncidencia),
    nextCursor
  };
};

export const actualizarEstadoIncidencia = async (datos: DatosActualizarIncidencia) => {
  if (!rolesCentral.includes(datos.rol)) {
    throw new ErrorHttp(403, 'Solo administracion puede gestionar incidencias');
  }

  return incidenciaRepositorio.ejecutarEnTransaccion(async (db) => {
    const incidencia = await incidenciaRepositorio.buscarPorId(datos.incidenciaId, db);

    if (!incidencia) {
      throw new ErrorHttp(404, 'Incidencia no encontrada');
    }

    if (estadosCerradosIncidencia.includes(incidencia.estado)) {
      throw new ErrorHttp(409, 'La incidencia ya está cerrada');
    }

    const respuesta = datos.respuesta?.trim() || null;
    const cerrada = estadosCerradosIncidencia.includes(datos.estado);

    if (cerrada && !respuesta) {
      throw new ErrorHttp(400, 'Debes indicar una respuesta para cerrar la incidencia');
    }

    const ahora = new Date();

    const actualizada = await incidenciaRepositorio.actualizar(
      incidencia.id,
      {
        estado: datos.estado,
        respuesta: respuesta ?? incidencia.respuesta,
        gestionadaPorUsuarioId: datos.usuarioId,
        resueltaEn: cerrada ? ahora : null
      },
      db
    );

    await crearNotificacion(
      {
        usuarioId: incidencia.reportadaPorUsuarioId,
        titulo: 'Incidencia actualizada',
        mensaje: `El estado del reporte en ${incidencia.bicicletero.nombre} cambió a ${etiquetaEstadoIncidencia(datos.estado)}.`,
        tipo: TipoNotificacion.INCIDENCIA,
        datos: { incidenciaId: incidencia.id, estado: datos.estado }
      },
      db
    );

    await registrarAuditoria(
      {
        actorUsuarioId: datos.usuarioId,
        accion: 'INCIDENCIA_ESTADO_ACTUALIZADO',
        entidad: 'incidencias',
        entidadId: incidencia.id,
        ip: datos.ip,
        userAgent: datos.userAgent,
        datos: {
          estadoAnterior: incidencia.estado,
          estadoNuevo: datos.estado,
          respuesta: respuesta ?? undefined
        }
      },
      db
    );

    emitirTiempoReal(
      [
        salaRol(RolUsuario.GUARDIA),
        salaRol(RolUsuario.ADMIN_CENTRAL),
        salaRol(RolUsuario.ADMINISTRADOR)
      ],
      EventosTiempoReal.INCIDENCIA
    );

    return mapearIncidencia(actualizada);
  });
};
