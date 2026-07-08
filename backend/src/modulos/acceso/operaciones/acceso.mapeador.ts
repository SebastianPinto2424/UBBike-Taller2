import { Prisma } from '../../../generated/prisma/client';

export const includeMovimientoCompleto = {
  usuario: true,
  bicicleta: true,
  bicicletero: true,
  validadoPorGuardia: true
} satisfies Prisma.MovimientoInclude;

export type MovimientoCompleto = Prisma.MovimientoGetPayload<{
  include: typeof includeMovimientoCompleto;
}>;

export const mapearMovimiento = (movimiento: MovimientoCompleto) => ({
  id: movimiento.id,
  tipo: movimiento.tipo,
  estado: movimiento.estado,
  motivoDenegacion: movimiento.motivoDenegacion,
  comentarioGuardia: movimiento.comentarioGuardia,
  origen: movimiento.origen,
  creadoEn: movimiento.creadoEn,
  usuario: {
    id: movimiento.usuario.id,
    nombre: movimiento.usuario.nombre,
    correo: movimiento.usuario.correo,
    rut: movimiento.usuario.rut
  },
  bicicleta: {
    id: movimiento.bicicleta.id,
    descripcion: movimiento.bicicleta.descripcion,
    marca: movimiento.bicicleta.marca,
    modelo: movimiento.bicicleta.modelo,
    color: movimiento.bicicleta.color,
    aro: movimiento.bicicleta.aro,
    numeroSerie: movimiento.bicicleta.numeroSerie,
    fotoUrl: movimiento.bicicleta.fotoUrl
  },
  bicicletero: {
    id: movimiento.bicicletero.id,
    nombre: movimiento.bicicletero.nombre
  },
  guardia: {
    id: movimiento.validadoPorGuardia.id,
    nombre: movimiento.validadoPorGuardia.nombre,
    correo: movimiento.validadoPorGuardia.correo
  }
});
