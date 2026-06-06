import { ErrorHttp } from '../../../comun/errors/error-http';
import { prisma, type ClientePrisma } from '../../../configuracion/prisma';
import { Prisma } from '../../../generated/prisma/client';
import { registrarAuditoria } from '../../auditoria/auditoria.servicio';
import {
  crearNotificacion,
  notificarUsuariosPorRol
} from '../../notificaciones/notificacion.servicio';
import { TipoNotificacion } from '../../notificaciones/tipo-notificacion';
import { RolUsuario } from '../../usuarios/rol-usuario';
import { EstadoSolicitudGuardia } from './estado-solicitud-guardia';
import { TipoSolicitudGuardia } from './tipo-solicitud-guardia';

type DatosCrearSolicitud = {
  usuarioId: string;
  bicicleteroId: string;
  tipo: TipoSolicitudGuardia;
  mensaje?: string | null;
};

type DatosNotificarGuardia = {
  usuarioId: string;
  rol: string;
  solicitudId: string;
  mensaje?: string | null;
};

type DatosListarSolicitudes = {
  usuarioId: string;
  rol: string;
  estado?: EstadoSolicitudGuardia | 'TODOS';
  q?: string;
  limite?: number;
};

const segundosEsperaRecordatorio = 90;
const rolesCentral: string[] = [RolUsuario.ADMINISTRADOR];
const rolesGestionSolicitudes: string[] = [RolUsuario.GUARDIA, RolUsuario.ADMINISTRADOR];
const estadosCerrados: EstadoSolicitudGuardia[] = [
  EstadoSolicitudGuardia.RESUELTA,
  EstadoSolicitudGuardia.CANCELADA
];

const etiquetaEstadoSolicitud = (estado: EstadoSolicitudGuardia) => {
  switch (estado) {
    case EstadoSolicitudGuardia.PENDIENTE:
      return 'pendiente';
    case EstadoSolicitudGuardia.NOTIFICADA:
      return 'guardia notificado';
    case EstadoSolicitudGuardia.EN_CAMINO:
      return 'guardia en camino';
    case EstadoSolicitudGuardia.RESUELTA:
      return 'resuelta';
    case EstadoSolicitudGuardia.CANCELADA:
      return 'cancelada';
    default:
      return estado;
  }
};

const tituloSolicitudParaUsuario = (estado: EstadoSolicitudGuardia) => {
  switch (estado) {
    case EstadoSolicitudGuardia.EN_CAMINO:
      return 'Guardia en camino';
    case EstadoSolicitudGuardia.RESUELTA:
      return 'Atención finalizada';
    case EstadoSolicitudGuardia.CANCELADA:
      return 'Solicitud cancelada';
    case EstadoSolicitudGuardia.NOTIFICADA:
      return 'Guardia notificado';
    default:
      return 'Solicitud actualizada';
  }
};

const mensajeSolicitudParaUsuario = (estado: EstadoSolicitudGuardia, bicicleteroNombre: string) => {
  switch (estado) {
    case EstadoSolicitudGuardia.EN_CAMINO:
      return `El guardia confirmó que va hacia ${bicicleteroNombre}.`;
    case EstadoSolicitudGuardia.RESUELTA:
      return `La solicitud en ${bicicleteroNombre} fue resuelta.`;
    case EstadoSolicitudGuardia.CANCELADA:
      return `La solicitud en ${bicicleteroNombre} fue cancelada.`;
    case EstadoSolicitudGuardia.NOTIFICADA:
      return `Tu recordatorio fue enviado al guardia asignado a ${bicicleteroNombre}.`;
    default:
      return `${bicicleteroNombre}: ${etiquetaEstadoSolicitud(estado)}.`;
  }
};

const includeSolicitudCompleta = {
  solicitadaPorUsuario: true,
  bicicletero: true,
  guardiaAsignado: true
} satisfies Prisma.SolicitudGuardiaInclude;

type SolicitudCompleta = Prisma.SolicitudGuardiaGetPayload<{
  include: typeof includeSolicitudCompleta;
}>;

const mapearUsuarioSolicitud = (
  usuario: SolicitudCompleta['solicitadaPorUsuario'] | SolicitudCompleta['guardiaAsignado']
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

const calcularSegundosParaRecordatorio = (solicitud: SolicitudCompleta) => {
  if (
    solicitud.respondidaPorGuardiaEn ||
    solicitud.estado === EstadoSolicitudGuardia.EN_CAMINO ||
    estadosCerrados.includes(solicitud.estado)
  ) {
    return null;
  }

  const base = solicitud.notificadaGuardiaEn ?? solicitud.creadaEn;
  const transcurridos = Math.floor((Date.now() - base.getTime()) / 1000);
  return Math.max(segundosEsperaRecordatorio - transcurridos, 0);
};

const mapearSolicitudGuardia = (solicitud: SolicitudCompleta) => {
  const segundosParaNotificarGuardia = calcularSegundosParaRecordatorio(solicitud);

  return {
    id: solicitud.id,
    tipo: solicitud.tipo,
    estado: solicitud.estado,
    mensaje: solicitud.mensaje,
    creadaEn: solicitud.creadaEn,
    notificadaGuardiaEn: solicitud.notificadaGuardiaEn,
    ultimaNotificacionUsuarioEn: solicitud.ultimaNotificacionUsuarioEn,
    notificacionesGuardia: solicitud.notificacionesGuardia,
    respondidaPorGuardiaEn: solicitud.respondidaPorGuardiaEn,
    enCaminoEn: solicitud.enCaminoEn,
    resueltaEn: solicitud.resueltaEn,
    puedeNotificarGuardia: Boolean(solicitud.guardiaAsignado) && segundosParaNotificarGuardia === 0,
    puedeNotificarGuardiaUsuario:
      Boolean(solicitud.guardiaAsignado) && !estadosCerrados.includes(solicitud.estado),
    segundosParaNotificarGuardia,
    bicicletero: {
      id: solicitud.bicicletero.id,
      nombre: solicitud.bicicletero.nombre,
      ubicacion: solicitud.bicicletero.ubicacion
    },
    solicitante: mapearUsuarioSolicitud(solicitud.solicitadaPorUsuario),
    guardiaAsignado: mapearUsuarioSolicitud(solicitud.guardiaAsignado),
    guardiasAsignados: solicitud.guardiaAsignado
      ? [mapearUsuarioSolicitud(solicitud.guardiaAsignado)]
      : []
  };
};

const validarRecordatorioCentral = (solicitud: SolicitudCompleta, rol: string) => {
  if (!rolesCentral.includes(rol)) {
    throw new ErrorHttp(403, 'Solo administracion puede reenviar la notificación al guardia');
  }

  if (!solicitud.guardiaAsignado) {
    throw new ErrorHttp(409, 'No hay guardia asignado para este bicicletero');
  }

  if (solicitud.respondidaPorGuardiaEn || solicitud.estado === EstadoSolicitudGuardia.EN_CAMINO) {
    throw new ErrorHttp(409, 'El guardia ya respondió esta solicitud');
  }

  if (estadosCerrados.includes(solicitud.estado)) {
    throw new ErrorHttp(409, 'La solicitud ya está cerrada');
  }

  const segundosRestantes = calcularSegundosParaRecordatorio(solicitud);

  if (segundosRestantes !== null && segundosRestantes > 0) {
    throw new ErrorHttp(
      409,
      `Administracion podra notificar nuevamente en ${segundosRestantes} segundos`
    );
  }
};

const notificarGuardiaAsignado = async (
  solicitud: SolicitudCompleta,
  db: ClientePrisma,
  titulo = 'Nueva solicitud de atención'
) => {
  if (!solicitud.guardiaAsignado) {
    return;
  }

  await crearNotificacion(
    {
      usuarioId: solicitud.guardiaAsignado.id,
      titulo,
      mensaje: `${solicitud.solicitadaPorUsuario.nombre} solicitó apoyo en ${solicitud.bicicletero.nombre}.`,
      tipo: TipoNotificacion.SOLICITUD_GUARDIA,
      datos: {
        solicitudId: solicitud.id,
        bicicleteroId: solicitud.bicicletero.id,
        solicitanteId: solicitud.solicitadaPorUsuario.id
      }
    },
    db
  );
};

const reiterarSolicitudAbierta = async (
  solicitud: SolicitudCompleta,
  usuarioId: string,
  rol: string,
  mensaje: string | null | undefined,
  db: ClientePrisma
) => {
  const esCentral = rolesCentral.includes(rol);
  const esSolicitante = solicitud.solicitadaPorUsuario.id === usuarioId;

  if (!esCentral && !esSolicitante) {
    throw new ErrorHttp(403, 'Solo el solicitante o administracion pueden notificar nuevamente');
  }

  if (estadosCerrados.includes(solicitud.estado)) {
    throw new ErrorHttp(409, 'La solicitud ya está cerrada');
  }

  const mensajeLimpio = mensaje?.trim();
  const ahora = new Date();

  if (!solicitud.guardiaAsignado) {
    const solicitudActualizada = await db.solicitudGuardia.update({
      where: { id: solicitud.id },
      data: {
        mensaje: mensajeLimpio || solicitud.mensaje
      },
      include: includeSolicitudCompleta
    });

    await notificarUsuariosPorRol(
      {
        roles: [RolUsuario.ADMINISTRADOR],
        titulo: 'Atención pendiente',
        mensaje: `El usuario reiteró una solicitud en ${solicitud.bicicletero.nombre}. Aún no hay guardia asignado.`,
        tipo: TipoNotificacion.SOLICITUD_GUARDIA,
        datos: {
          solicitudId: solicitud.id,
          bicicleteroId: solicitud.bicicletero.id,
          solicitanteId: solicitud.solicitadaPorUsuario.id
        }
      },
      db
    );

    await registrarAuditoria(
      {
        actorUsuarioId: usuarioId,
        accion: 'SOLICITUD_GUARDIA_REITERADA_SIN_GUARDIA',
        entidad: 'solicitudes_guardia',
        entidadId: solicitud.id,
        datos: {
          rolActor: rol,
          bicicleteroId: solicitud.bicicletero.id
        }
      },
      db
    );

    return solicitudActualizada;
  }

  const solicitudActualizada = await db.solicitudGuardia.update({
    where: { id: solicitud.id },
    data: {
      estado:
        solicitud.estado === EstadoSolicitudGuardia.PENDIENTE
          ? EstadoSolicitudGuardia.NOTIFICADA
          : solicitud.estado,
      mensaje: mensajeLimpio || solicitud.mensaje,
      notificadaGuardiaEn: ahora,
      ultimaNotificacionUsuarioEn: esSolicitante ? ahora : solicitud.ultimaNotificacionUsuarioEn,
      notificacionesGuardia: {
        increment: 1
      }
    },
    include: includeSolicitudCompleta
  });

  await notificarGuardiaAsignado(solicitudActualizada, db);

  await registrarAuditoria(
    {
      actorUsuarioId: usuarioId,
      accion: 'SOLICITUD_GUARDIA_RENOTIFICADA',
      entidad: 'solicitudes_guardia',
      entidadId: solicitud.id,
      datos: {
        rolActor: rol,
        bicicleteroId: solicitud.bicicletero.id,
        guardiaAsignadoId: solicitud.guardiaAsignado.id,
        notificacionesGuardia: solicitudActualizada.notificacionesGuardia
      }
    },
    db
  );

  return solicitudActualizada;
};

export const crearSolicitudGuardia = async (datos: DatosCrearSolicitud) => {
  return prisma.$transaction(async (db) => {
    const bicicletero = await db.bicicletero.findUnique({
      where: {
        id: datos.bicicleteroId
      }
    });

    if (!bicicletero) {
      throw new ErrorHttp(404, 'Bicicletero no encontrado');
    }

    const solicitudAbierta = await db.solicitudGuardia.findFirst({
      where: {
        solicitadaPorUsuarioId: datos.usuarioId,
        bicicleteroId: bicicletero.id,
        tipo: datos.tipo,
        estado: {
          notIn: estadosCerrados
        }
      },
      include: includeSolicitudCompleta,
      orderBy: {
        creadaEn: 'desc'
      }
    });

    if (solicitudAbierta) {
      const solicitudReiterada = await reiterarSolicitudAbierta(
        solicitudAbierta,
        datos.usuarioId,
        solicitudAbierta.solicitadaPorUsuario.rol,
        datos.mensaje,
        db
      );

      await crearNotificacion(
        {
          usuarioId: datos.usuarioId,
          titulo: solicitudReiterada.guardiaAsignado ? 'Guardia notificado' : 'Solicitud reiterada',
          mensaje: solicitudReiterada.guardiaAsignado
            ? `Tu recordatorio fue enviado al guardia asignado a ${bicicletero.nombre}.`
            : `Administracion recibio nuevamente tu solicitud para ${bicicletero.nombre}.`,
          tipo: TipoNotificacion.SOLICITUD_GUARDIA,
          datos: { solicitudId: solicitudReiterada.id, accionPropia: true }
        },
        db
      );

      return mapearSolicitudGuardia(solicitudReiterada);
    }

    const asignacion = await db.asignacionGuardia.findFirst({
      where: {
        bicicleteroId: datos.bicicleteroId,
        activa: true
      },
      include: {
        guardia: true
      },
      orderBy: {
        iniciaEn: 'desc'
      }
    });

    const solicitudGuardada = await db.solicitudGuardia.create({
      data: {
        solicitadaPorUsuarioId: datos.usuarioId,
        bicicleteroId: bicicletero.id,
        guardiaAsignadoId: asignacion?.guardia.id ?? null,
        tipo: datos.tipo,
        estado: asignacion?.guardia
          ? EstadoSolicitudGuardia.NOTIFICADA
          : EstadoSolicitudGuardia.PENDIENTE,
        mensaje: datos.mensaje || null,
        notificadaGuardiaEn: asignacion?.guardia ? new Date() : null,
        ultimaNotificacionUsuarioEn: asignacion?.guardia ? new Date() : null,
        notificacionesGuardia: asignacion?.guardia ? 1 : 0
      }
    });

    await crearNotificacion(
      {
        usuarioId: datos.usuarioId,
        titulo: asignacion?.guardia ? 'Guardia notificado' : 'Atención solicitada',
        mensaje: asignacion?.guardia
          ? `Tu solicitud fue enviada al guardia asignado a ${bicicletero.nombre}.`
          : `Administracion recibio tu solicitud para ${bicicletero.nombre}.`,
        tipo: TipoNotificacion.SOLICITUD_GUARDIA,
        datos: { solicitudId: solicitudGuardada.id, accionPropia: true }
      },
      db
    );

    if (asignacion?.guardia) {
      await crearNotificacion(
        {
          usuarioId: asignacion.guardia.id,
          titulo: 'Atención requerida',
          mensaje: `Hay una solicitud pendiente en ${bicicletero.nombre}.`,
          tipo: TipoNotificacion.SOLICITUD_GUARDIA,
          datos: { solicitudId: solicitudGuardada.id, bicicleteroId: bicicletero.id }
        },
        db
      );
    }

    await notificarUsuariosPorRol(
      {
        roles: [RolUsuario.ADMINISTRADOR],
        titulo: 'Nueva solicitud de atención',
        mensaje: `Un usuario solicitó apoyo en ${bicicletero.nombre}.`,
        tipo: TipoNotificacion.SOLICITUD_GUARDIA,
        datos: { solicitudId: solicitudGuardada.id, bicicleteroId: bicicletero.id }
      },
      db
    );

    await registrarAuditoria(
      {
        actorUsuarioId: datos.usuarioId,
        accion: 'SOLICITUD_GUARDIA_CREADA',
        entidad: 'solicitudes_guardia',
        entidadId: solicitudGuardada.id,
        datos: {
          bicicleteroId: bicicletero.id,
          guardiaAsignadoId: asignacion?.guardia.id ?? null,
          tipo: datos.tipo
        }
      },
      db
    );

    const solicitudCompleta = await db.solicitudGuardia.findUniqueOrThrow({
      where: { id: solicitudGuardada.id },
      include: includeSolicitudCompleta
    });

    return mapearSolicitudGuardia(solicitudCompleta);
  });
};

export const listarSolicitudesGuardia = async (datos: DatosListarSolicitudes) => {
  const condiciones: Prisma.SolicitudGuardiaWhereInput[] = [];

  if (datos.rol === RolUsuario.GUARDIA) {
    condiciones.push({ guardiaAsignadoId: datos.usuarioId });
  } else if (!rolesCentral.includes(datos.rol)) {
    condiciones.push({ solicitadaPorUsuarioId: datos.usuarioId });
  }

  if (datos.estado && datos.estado !== 'TODOS') {
    condiciones.push({ estado: datos.estado });
  }

  const q = datos.q?.trim();
  if (q) {
    condiciones.push({
      OR: [
        { mensaje: { contains: q, mode: 'insensitive' } },
        { bicicletero: { nombre: { contains: q, mode: 'insensitive' } } },
        { bicicletero: { ubicacion: { contains: q, mode: 'insensitive' } } },
        { solicitadaPorUsuario: { nombre: { contains: q, mode: 'insensitive' } } },
        { solicitadaPorUsuario: { correo: { contains: q, mode: 'insensitive' } } },
        { solicitadaPorUsuario: { rut: { contains: q, mode: 'insensitive' } } },
        { guardiaAsignado: { is: { nombre: { contains: q, mode: 'insensitive' } } } },
        { guardiaAsignado: { is: { correo: { contains: q, mode: 'insensitive' } } } }
      ]
    });
  }

  const limite = datos.limite && datos.limite > 0 ? Math.min(datos.limite, 500) : undefined;
  const solicitudes = await prisma.solicitudGuardia.findMany({
    where: condiciones.length ? { AND: condiciones } : {},
    include: includeSolicitudCompleta,
    orderBy: {
      creadaEn: 'desc'
    },
    ...(limite ? { take: limite } : {})
  });

  return solicitudes.map(mapearSolicitudGuardia);
};

export const notificarGuardiaSolicitud = async (datos: DatosNotificarGuardia) => {
  return prisma.$transaction(async (db) => {
    const solicitud = await db.solicitudGuardia.findUnique({
      where: { id: datos.solicitudId },
      include: includeSolicitudCompleta
    });

    if (!solicitud) {
      throw new ErrorHttp(404, 'Solicitud no encontrada');
    }

    const solicitudActualizada = await reiterarSolicitudAbierta(
      solicitud,
      datos.usuarioId,
      datos.rol,
      datos.mensaje,
      db
    );

    await crearNotificacion(
      {
        usuarioId: solicitud.solicitadaPorUsuario.id,
        titulo: solicitudActualizada.guardiaAsignado
          ? 'Guardia notificado'
          : 'Administracion notificada nuevamente',
        mensaje: solicitudActualizada.guardiaAsignado
          ? `Tu recordatorio fue enviado al guardia asignado a ${solicitud.bicicletero.nombre}.`
          : `Administracion recibio nuevamente tu solicitud para ${solicitud.bicicletero.nombre}.`,
        tipo: TipoNotificacion.SOLICITUD_GUARDIA,
        datos: {
          solicitudId: solicitud.id,
          accionPropia: datos.usuarioId === solicitud.solicitadaPorUsuario.id
        }
      },
      db
    );

    return mapearSolicitudGuardia(solicitudActualizada);
  });
};

export const actualizarEstadoSolicitudGuardia = async (
  usuarioId: string,
  rol: string,
  solicitudId: string,
  estado: EstadoSolicitudGuardia
) => {
  if (!rolesGestionSolicitudes.includes(rol)) {
    throw new ErrorHttp(403, 'No tienes permisos para actualizar solicitudes');
  }

  return prisma.$transaction(async (db) => {
    const solicitud = await db.solicitudGuardia.findUnique({
      where: { id: solicitudId },
      include: includeSolicitudCompleta
    });

    if (!solicitud) {
      throw new ErrorHttp(404, 'Solicitud no encontrada');
    }

    if (estadosCerrados.includes(solicitud.estado)) {
      throw new ErrorHttp(409, 'La solicitud ya está cerrada');
    }

    if (rol === RolUsuario.GUARDIA && solicitud.guardiaAsignado?.id !== usuarioId) {
      throw new ErrorHttp(403, 'La solicitud no está asignada a este guardia');
    }

    if (estado === EstadoSolicitudGuardia.NOTIFICADA) {
      validarRecordatorioCentral(solicitud, rol);
    }

    const guardiaResponde =
      rol === RolUsuario.GUARDIA && estado === EstadoSolicitudGuardia.EN_CAMINO;
    const ahora = new Date();

    const solicitudActualizada = await db.solicitudGuardia.update({
      where: { id: solicitud.id },
      data: {
        estado,
        notificadaGuardiaEn:
          estado === EstadoSolicitudGuardia.NOTIFICADA ? ahora : solicitud.notificadaGuardiaEn,
        notificacionesGuardia:
          estado === EstadoSolicitudGuardia.NOTIFICADA
            ? {
                increment: 1
              }
            : undefined,
        respondidaPorGuardiaEn:
          guardiaResponde && !solicitud.respondidaPorGuardiaEn
            ? ahora
            : solicitud.respondidaPorGuardiaEn,
        enCaminoEn:
          estado === EstadoSolicitudGuardia.EN_CAMINO
            ? (solicitud.enCaminoEn ?? ahora)
            : solicitud.enCaminoEn,
        resueltaEn:
          estado === EstadoSolicitudGuardia.RESUELTA || estado === EstadoSolicitudGuardia.CANCELADA
            ? ahora
            : null
      },
      include: includeSolicitudCompleta
    });

    await crearNotificacion(
      {
        usuarioId: solicitud.solicitadaPorUsuario.id,
        titulo: tituloSolicitudParaUsuario(estado),
        mensaje: mensajeSolicitudParaUsuario(estado, solicitud.bicicletero.nombre),
        tipo: TipoNotificacion.SOLICITUD_GUARDIA,
        datos: { solicitudId: solicitud.id, estado }
      },
      db
    );

    if (estado === EstadoSolicitudGuardia.NOTIFICADA && rolesCentral.includes(rol)) {
      await crearNotificacion(
        {
          usuarioId: solicitud.guardiaAsignado!.id,
          titulo: 'Recordatorio de atención',
          mensaje: `Administracion solicito atender ${solicitud.bicicletero.nombre}.`,
          tipo: TipoNotificacion.SOLICITUD_GUARDIA,
          datos: {
            solicitudId: solicitud.id,
            bicicleteroId: solicitud.bicicletero.id,
            estado
          }
        },
        db
      );
    }

    if (guardiaResponde) {
      await notificarUsuariosPorRol(
        {
          roles: [RolUsuario.ADMINISTRADOR],
          titulo: 'Guardia en camino',
          mensaje: `${solicitud.guardiaAsignado!.nombre} confirmó traslado hacia ${solicitud.bicicletero.nombre}.`,
          tipo: TipoNotificacion.SOLICITUD_GUARDIA,
          datos: {
            solicitudId: solicitud.id,
            bicicleteroId: solicitud.bicicletero.id,
            estado
          }
        },
        db
      );
    }

    await registrarAuditoria(
      {
        actorUsuarioId: usuarioId,
        accion: 'SOLICITUD_GUARDIA_ESTADO_ACTUALIZADO',
        entidad: 'solicitudes_guardia',
        entidadId: solicitud.id,
        datos: {
          estado,
          rolActor: rol,
          bicicleteroId: solicitud.bicicletero.id,
          guardiaAsignadoId: solicitud.guardiaAsignado?.id ?? null
        }
      },
      db
    );

    return mapearSolicitudGuardia(solicitudActualizada);
  });
};
